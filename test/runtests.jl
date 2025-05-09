# Test Data containers

using CrystalInfoContainers
using CrystalInfoFramework
using Test

# Test a plain CIF as data source

const cif_test_file = joinpath(@__DIR__,"nick1.cif")
const multi_block_test_file = joinpath(@__DIR__,"cif_img_1.7.11.dic")
const core_dic = joinpath(@__DIR__,"cif_core.dic")

# This just sets up access to a particular block
prepare_block(filename, blockname; native=false) = begin
    t = Cif(joinpath(@__DIR__, "test_cifs", filename), native=native)
    b = t[blockname]
end

prepare_files() = begin
    c = Cif(cif_test_file)
    b = first(c).second
end

prepare_blocks() = begin
    c = MultiDataSource(Cif(multi_block_test_file))
end

prepare_sources() = begin
    cdic = DDLm_Dictionary(core_dic)
    data = prepare_files()
    return (cdic,data)
end

@testset "Test simple dict as DataSource" begin
    testdic = Dict("a"=>[1,2,3],"b"=>[4,5,6],"c"=>[0],"d"=>[11,12])
    @test get_assoc_index(testdic,"b",3,"a") == 3
    @test get_all_associated_indices(testdic,"b","a") == [1,2,3]
    @test get_all_associated_indices(testdic,"b","c") == [1,1,1]
    @test get_assoc_value(testdic,"b",3,"a") == 3
    @test collect(get_all_associated_values(testdic,"b","a")) == [1,2,3]
    @test collect(get_all_associated_values(testdic,"b","c")) == [0,0,0]
end

@testset "Test CIF block as DataSource" begin

    # Within loop
    @test begin
        b = prepare_files()
        q = get_assoc_value(b,"_atom_type.atomic_mass",2,"_atom_type.symbol")
        println("Test 1: q is $q")
        q == "C"
    end

    # With constant value
    @test begin
        b = prepare_files()
        get_assoc_value(b,"_atom_type_scat.dispersion_imag",3,"_cell.volume") == "635.3(11)"
    end

    # Get all values
    @test begin
        b = prepare_files()
        q = collect(get_all_associated_values(b,"_atom_type.number_in_cell","_atom_type.symbol"))
        println("Test 3: $q")
        q == ["O","C","H"]
    end

    # And if its a constant...
    @test begin
        b = prepare_files()
        q = collect(get_all_associated_values(b,"_atom_type_scat.source","_chemical_formula.sum"))
        q == fill("C7 H6 O3",3)
    end
    
end


@testset "Test multi data block as DataSource" begin
    @test begin            #enclosing scope
        b = prepare_blocks()
        r = get_assoc_value(b,"_item_type.code",3,"_dictionary.datablock_id")
        println(r)
        r == "cif_img.dic"
    end

    @test begin            #same save frame loop
        b = prepare_blocks()
        r = get_assoc_value(b,"_item.mandatory_code",6,"_item.name")
        println(r)
        mb = first(b.wrapped).second
        defblock = mb.save_frames[r]
        defblock["_item.mandatory_code"][1] == b["_item.mandatory_code"][6]
    end

    @test begin
        b = prepare_blocks()
        ai = get_all_associated_indices(b,"_item.category_id","_item_type.code")
        ac = b["_item.category_id"]
        length(ai) == length(ac)
    end
    
    @test begin            #same save frame, no loop
        b = prepare_blocks()
        #r = get_assoc_value(b,"_item.category_id",4,"_item_type.code")
        # now we have to check!
        mb = first(b.wrapped).second
        s = get_assoc_value(b,"_item.category_id",4,"_item.name")
        println("Testing definition $s")
        defblock = mb.save_frames[s]
        ai = get_all_associated_indices(b,"_item.category_id","_item_type.code")
        an = get_all_associated_indices(b,"_item.category_id","_item.name")
        ac = b["_item.category_id"]
        at = b["_item_type.code"]
        names = b["_item.name"]
        println("$(at[ai[4]])")
        println("$(names[an[4]])")
        println("$(defblock)")
        at[ai[4]] == defblock["_item_type.code"][1] 
    end
end

@testset "Test TypedDataSources" begin
    cdic,data = prepare_sources()
    t = TypedDataSource(data,cdic)
    @test t["_cell.volume"][] == 635.3
    @test t["_cell_volume"][] == 635.3
    @test haskey(t,"_atom_type.symbol")
    @test haskey(t,"_atom_type_symbol")
    @test !haskey(t,"this_key_does_not_exist")
    q = get_assoc_value(t,"_atom_type.atomic_mass",2,"_atom_type.symbol")
    @test q == "C"
    q = get_assoc_value(t,"_atom_type.atomic_mass",2,"_cell_volume")
    @test q == 635.3
    q = get_all_associated_indices(t,"_atom_site.fract_x","_atom_site.label")
    @test length(q) == length(t["_atom_site.fract_x"])
    q = get_all_associated_indices(t,"_atom_site_fract_x","_atom_site_label")
    @test length(q) == length(t["_atom_site_fract_x"]) #aliases
end

prepare_rc() = begin
    cdic, data = prepare_sources()
    ddata = TypedDataSource(data, cdic)
    RelationalContainer(ddata) 
end

@testset "Test construction of RelationalContainers from Datasources and dictionaries" begin
    my_rc = prepare_rc()
    @test length(get_category(my_rc, "atom_type")[:atomic_mass]) == 3
    @test length(get_category(my_rc, "cell")) == 1
    @test get_category(my_rc, "cell")[:volume][] == 635.3
    @test find_namespace(my_rc, "atom_site") == "CifCore"
    @test CrystalInfoContainers.has_category(my_rc, "cell")
    @test "_atom_site.fract_y" in keys(my_rc)
    # getindex
    @test my_rc[:atom_type, :atomic_mass] == [15.999, 12.011, 1.008]
end

@testset "Test construction of a CifCategory" begin
    my_rc = prepare_rc()
    atom_cat = LoopCategory(my_rc, "atom_site")
    @test get_key_datanames(atom_cat) == [:label, :diffrn_id]
    # Test getting a particular value
    mypacket = CatPacket(3, atom_cat)
    @test get_value(mypacket, :fract_x) == .2501
    # Test relation interface
    @test get_value(atom_cat, Dict(:label=>"o2"), :fract_z) == .229
    # Test missing data
    empty_cat = LoopCategory(my_rc, "diffrn_orient_refln")
    # Test set category
    set_cat = LoopCategory(my_rc, "cell")
    @test set_cat[:volume][] == 635.3
    # Test getting a key value
    @test atom_cat["o2"].fract_z == .229
end

@testset "Test child categories" begin
    
    my_rc = prepare_rc()
    atom_cat = LoopCategory(my_rc, "atom_site")
    @test get_value(atom_cat,Dict(:label=>"o2"),:u_11) == .029

end

@testset "Test behaviour of plain CatPackets" begin
    my_rc  = prepare_rc()
    atom_cat = LoopCategory(my_rc, "atom_site")
    for one_pack in atom_cat
        @test !ismissing(one_pack.fract_x)
        if one_pack.label == "o2"
            @test one_pack.fract_z == .229
        end
    end
end

include("namespaces.jl")
