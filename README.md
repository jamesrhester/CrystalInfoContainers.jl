# CrystalInfoContainers.jl

A Julia package for using Crystallographic Information Framework (CIF)
dictionaries to work with arbitrary data, by assigning CIF data names
to objects in source data files. The relational and typing information
in the dictionary can then be used to access data from various sources
in a uniform way, or to perform calculations provided by the dictionary
in dREL.

## DataSources

A ``DataSource`` is any data source returning an array of values when
supplied with a string.  A CIF ``Block`` conforms to this specification.
``DataSource``s are defined in submodule ``DataContainer``.

A CIF dictionary can be used to obtain data with correct Julia type from
a ``DataSource`` that uses data names defined in the dictionary by 
creating a ``TypedDataSource``:

```julia
julia> using CrystalInfoFramework

julia> nc = Cif("my_cif.cif")
...
julia> my_block = nc["only_block"]  #could also use first(nc).second

julia> using CrystalInfoContainer
julia> my_dict = DDLm_Dictionary("cif_core.dic")
julia> bd = TypedDataSource(my_block,my_dict)
julia> l = bd["_cell.length_a"]
1-element Array{Float64,1}:
 11.52
julia> l = bd["_cell_length_a"] #understand aliases
1-element Array{Float64,1}:
 11.52
```
