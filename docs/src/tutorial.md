# Guide

The CIF files used in these examples are provided in the `docs`
directory.

This module combines CIF dictionaries with arbitrary data sources
to simplify manipulation, typing and calculations of objects
within those data sources.

## DataSources

CIF dictionaries can be used with any `DataSource`, providing
that the datasource recognises the data names defined in the dictionary.

A `DataSource` is any object returning an array of values when
supplied with a string - where that string is typically a CIF data
name.  A CIF `Block` conforms to this
specification, as does a simple `Dict{String, Any}`.

A CIF dictionary can be used to obtain data with correct Julia type from
a `DataSource` that uses data names defined in the dictionary by 
creating a [`TypedDataSource`](@ref):

```jldoctest nick1
using CrystalInfoContainers, CrystalInfoFramework, DataFrames
nc = Cif("demo.cif")
my_block = nc["saly2_all_aniso"]  #could also use first(nc).second
my_dict = DDLm_Dictionary("../test/cif_core.dic")
bd = TypedDataSource(my_block,my_dict)
bd["_cell.length_a"]

# output

1-element Vector{Float64}:
 11.52

```

Note that the array elements are now `Float64` and that the standard
uncertainty has been removed. Future improvements may use
`Measurements.jl` to retain standard uncertainties. Meanwhile,
SUs are available by appending `_su` to the data name.

Dictionaries also allow alternative names for a data name to be
recognised provided these are noted in the dictionary:

```jldoctest nick1

l = bd["_cell_length_a"] #no period in name

# output

1-element Vector{Float64}:
 11.52

```

where `_cell_length_a` is the old form of the data name.

Currently transformations from `DataSource` values to Julia values
assume that the `DataSource` values are either already of the correct
type, or are `String`s that can be directly parsed by the Julia
`parse` method.

### Creating new DataSources

A file format can be used with CIF dictionaries if:

1. It returns an `Array` of values when provided with a data name defined in the dictionary
2. `Array`s returned for data names from the same CIF category have corresponding values at the same position in the array - that is, they line up correctly if presented as columns in a table.

At a minimum, the following methods should be defined for the `DataSource`: 
`getindex`, `haskey`.

If the above are true of your type, then it is sufficient to define
`DataSource(::MyType) = IsDataSource()` to make it available.

If a `DataSource` can instead be modelled as a collection of
`DataSource`s, `iterate_blocks` should also be defined to iterate over
the constituent `DataSource`s. `MultiDataSource(<file>)` will then create
a `DataSource` where values returned for any data names defined in the
constituent blocks are automatically aligned. Such `MultiDataSource`
objects can be built to form hierarchies.

## Types

A `TypedDataSource` consists of a `DataSource` and a CIF dictionary.

Values returned from a `TypedDataSource` are transformed to the appropriate
Julia type as specified by the dictionary *if* the underlying 
`DataSource` returns `String` values formatted in a way that Julia `parse`
can understand.  Otherwise, the `DataSource` is responsible
for returning the appropriate Julia type. Future improvements
may add user-defined transformations if that proves necesssary.

A `NamespacedTypedDataSource` includes data from multiple namespaces.
Correctly-typed data for a particular namespace can then be obtained from 
the object returned by `select_namespace(t::NamespacedTypedDataSource,nspace)`.

## Relational containers

CIF dictionaries organise data names into relations (tables). These relations
are strictly conformant to the relational model. A `RelationalContainer` is
an object created from a `DataSource` and CIF dictionary which provides a
relational view of `DataSource`, that is, data are organised into tables
according to the dictionary specifications.

### Cif Categories

A CIF category (a 'Relation' in the relational model) can be returned
from a `RelationalContainer` given the category name:

```jldoctest nick1

rc = RelationalContainer(my_block, my_dict)  # Use DataSource to create RelationalContainer
as = LoopCategory(rc, "atom_site")

# output

Category atom_site Length 10
10×7 DataFrame
 Row │ fract_x   fract_z    label  adp_type  u_iso_or_equiv  occupancy  fract_ ⋯
     │ Any       Any        Any    Any       Any             Any        Any    ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ .5505(5)  .1605(11)  o1     Uani      .035(3)         1.00000    .6374( ⋯
   2 │ .4009(5)  .2290(11)  o2     Uani      .033(3)         1.00000    .5162(
   3 │ .2501(5)  .6014(13)  o3     Uani      .043(4)         1.00000    .5707(
   4 │ .4170(7)  .4954(15)  c1     Uani      .029(4)         1.00000    .6930(
   5 │ .3145(7)  .6425(16)  c2     Uani      .031(5)         1.00000    .6704( ⋯
   6 │ .2789(8)  .8378(17)  c3     Uani      .040(5)         1.00000    .7488(
   7 │ .3417(9)  .8859(18)  c4     Uani      .045(6)         1.00000    .8529(
   8 │ .4445(9)  .7425(18)  c5     Uani      .045(6)         1.00000    .8778(
   9 │ .4797(8)  .5487(17)  c6     Uani      .038(5)         1.00000    .7975( ⋯
  10 │ .4549(7)  .2873(16)  c7     Uani      .029(4)         1.00000    .6092(
                                                                1 column omitted

```

where a category is either a `LoopCategory`, with one or more rows, or
a `SetCategory`, which is restricted to a single row.

`getindex` for CIF categories uses the indexing value as the *key value*
for looking up a row in the category:

```jldoctest nick1
one_row = as["o1"]
one_row.fract_x

# output

".5505(5)"

```

If a category key consists multiple data names, a `Dict{Symbol,V}` should
be provided as the indexing value, where `Symbol` is the `object_id` of
the particular data name forming part of the key and `V` is the type of
the values.

A category can be iterated over as usual, with the value of each dataname
for each row available as a property:

```jldoctest nick1
for one_row in as
    println("$(one_row.label) $(one_row.fract_x) $(one_row.fract_y) $(one_row.fract_z)")
end

# output

o1 .5505(5) .6374(5) .1605(11)
o2 .4009(5) .5162(5) .2290(11)
o3 .2501(5) .5707(5) .6014(13)
c1 .4170(7) .6930(8) .4954(15)
c2 .3145(7) .6704(8) .6425(16)
c3 .2789(8) .7488(8) .8378(17)
c4 .3417(9) .8529(8) .8859(18)
c5 .4445(9) .8778(9) .7425(18)
c6 .4797(8) .7975(8) .5487(17)
c7 .4549(7) .6092(7) .2873(16)

```

If you prefer the `DataFrame` tools for working with tables, `DataFrame(c::CifCategory)`
creates a `DataFrame`:

```jldoctest nick1

DataFrame(as)

# output

10×7 DataFrame
 Row │ fract_x   fract_z    label  adp_type  u_iso_or_equiv  occupancy  fract_ ⋯
     │ Any       Any        Any    Any       Any             Any        Any    ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ .5505(5)  .1605(11)  o1     Uani      .035(3)         1.00000    .6374( ⋯
   2 │ .4009(5)  .2290(11)  o2     Uani      .033(3)         1.00000    .5162(
   3 │ .2501(5)  .6014(13)  o3     Uani      .043(4)         1.00000    .5707(
   4 │ .4170(7)  .4954(15)  c1     Uani      .029(4)         1.00000    .6930(
   5 │ .3145(7)  .6425(16)  c2     Uani      .031(5)         1.00000    .6704( ⋯
   6 │ .2789(8)  .8378(17)  c3     Uani      .040(5)         1.00000    .7488(
   7 │ .3417(9)  .8859(18)  c4     Uani      .045(6)         1.00000    .8529(
   8 │ .4445(9)  .7425(18)  c5     Uani      .045(6)         1.00000    .8778(
   9 │ .4797(8)  .5487(17)  c6     Uani      .038(5)         1.00000    .7975( ⋯
  10 │ .4549(7)  .2873(16)  c7     Uani      .029(4)         1.00000    .6092(
                                                                1 column omitted

```

