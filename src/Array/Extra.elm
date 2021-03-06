module Array.Extra exposing
    ( filterMap, apply, mapToList, indexedMapToList, map2, map3, map4, map5, removeWhen, reverse
    , zip, zip3, unzip
    , sliceFrom, sliceUntil, resizelRepeat, resizerRepeat, resizelIndexed, resizerIndexed, splitAt
    , removeAt, insertAt, pop, update
    )

{-| Convenience functions for working with Array


# Transform

@docs filterMap, apply, mapToList, indexedMapToList, map2, map3, map4, map5, removeWhen, reverse


# Zip

@docs zip, zip3, unzip


# Slice / resize

@docs sliceFrom, sliceUntil, resizelRepeat, resizerRepeat, resizelIndexed, resizerIndexed, splitAt


# Modify

@docs removeAt, insertAt, pop, update

-}

import Array exposing (..)


{-| Update the element at the index using a function. Returns the array unchanged if the index is out of bounds.

    update 1 ((+) 10) (fromList [ 1, 2, 3 ])
        == fromList [ 1, 12, 3 ]

    update 4 ((+) 10) (fromList [ 1, 2, 3 ])
        == fromList [ 1, 2, 3 ]

    update -1 ((+) 10) (fromList [ 1, 2, 3 ])
        == fromList [ 1, 2, 3 ]

-}
update : Int -> (a -> a) -> Array a -> Array a
update n f a =
    let
        element =
            Array.get n a
    in
    case element of
        Nothing ->
            a

        Just element_ ->
            Array.set n (f element_) a


{-| Drop _n_ first elements from an array.
In other words, slice an array from an index until the very end.
Given negative argument, count the end of the slice from the end of the array.

    sliceFrom 3 (fromList (List.range 0 6))
        == fromList [ 3, 4, 5, 6 ]

    sliceFrom -3 (fromList (List.range 0 6))
        == fromList [ 4, 5, 6 ]

-}
sliceFrom : Int -> Array a -> Array a
sliceFrom n array =
    slice n (length array) array


{-| Take _n_ first elements from an array.
In other words, slice an array from the very beginning until index not including.
Given negative argument, count the beginning of the slice from the end of the array.

    sliceUntil 3 (fromList (List.range 0 6))
        == fromList [ 0, 1, 2 ]

    sliceUntil -3 (fromList (List.range 0 6))
        == fromList [ 0, 1, 2, 3 ]

-}
sliceUntil : Int -> Array a -> Array a
sliceUntil newLength array =
    slice 0
        (if newLength >= 0 then
            newLength

         else
            length array + newLength
        )
        array


{-| Remove the last element from an array.

    pop (fromList [ 1, 2, 3 ]) == fromList [ 1, 2 ]

    pop empty == empty

-}
pop : Array a -> Array a
pop array =
    slice 0 -1 array


{-| Apply a function that may succeed to all values in the array, but only keep the successes.

    String.toInt : String -> Maybe Int
    filterMap String.toInt
        (fromList [ "3", "4.0", "5", "hats" ])
        == fromList [ 3, 5 ]

-}
filterMap : (a -> Maybe b) -> Array a -> Array b
filterMap tryMap array =
    array
        |> Array.toList
        |> List.filterMap tryMap
        |> Array.fromList


{-| Apply an array of functions to an array of values.

    apply
        (fromList
            [ \x -> -x
            , identity
            , always 0
            ]
        )
        (repeat 5 100)
        == fromList [ -100, 100, 0 ]

-}
apply : Array (a -> b) -> Array a -> Array b
apply maps array =
    map2 (\f b -> f b) maps array


{-| Apply a function to the array, collecting the result in a List.
This is useful for building HTML out of an array:

    Html.text : String -> Html msg
    mapToList Html.text : Array String -> List (Html msg)

-}
mapToList : (a -> b) -> Array a -> List b
mapToList alter =
    Array.foldr (alter >> (::)) []


{-| Apply a function to the array with the index as the first argument,
collecting the results in a List.

    type alias Exercise =
        { name : String }

    renderExercise : Int -> Exercise -> Html msg
    renderExercise index exercise =
        String.concat
            [ "Exercise #"
            , String.fromInt (index + 1)
            , " - "
            , exercise.name
            ]
            |> Html.text

    renderExercises : Array Exercise -> Html msg
    renderExercises exercises =
        indexedMapToList renderExercise exercises
            |> Html.div []

-}
indexedMapToList : (Int -> a -> b) -> Array a -> List b
indexedMapToList mapIndexAndValue array =
    Array.foldr
        (\x ( i, ys ) ->
            ( i - 1, mapIndexAndValue i x :: ys )
        )
        ( Array.length array - 1, [] )
        array
        |> Tuple.second


{-| Combine two arrays, combining them with the given function.
If one array is longer, the extra elements are dropped.

    map2 (+) [ 1, 2, 3 ] [ 1, 2, 3, 4 ]
        == [ 2, 4, 6 ]

    map2 Tuple.pair [ 1, 2, 3 ] [ 'a', 'b' ]
        == [ ( 1, 'a' ), ( 2, 'b' ) ]

    pairs : Array a -> Array b -> Array ( a, b )
    pairs lefts rights =
        map2 Tuple.pair lefts rights

-}
map2 : (a -> b -> result) -> Array a -> Array b -> Array result
map2 combineAb aArray bArray =
    List.map2 combineAb
        (aArray |> Array.toList)
        (bArray |> Array.toList)
        |> Array.fromList


{-| -}
map3 :
    (a -> b -> c -> result)
    -> Array a
    -> Array b
    -> Array c
    -> Array result
map3 combineAbc aArray bArray cArray =
    apply (map2 combineAbc aArray bArray) cArray


{-| -}
map4 :
    (a -> b -> c -> d -> result)
    -> Array a
    -> Array b
    -> Array c
    -> Array d
    -> Array result
map4 combineAbcd aArray bArray cArray dArray =
    apply (map3 combineAbcd aArray bArray cArray) dArray


{-| -}
map5 :
    (a -> b -> c -> d -> e -> result)
    -> Array a
    -> Array b
    -> Array c
    -> Array d
    -> Array e
    -> Array result
map5 combineAbcde aArray bArray cArray dArray eArray =
    apply (map4 combineAbcde aArray bArray cArray dArray) eArray


{-| Return an array that only contains elements which fail to satisfy the predicate.
This is equivalent to `Array.filter (not << predicate)`.

    removeWhen isEven (fromList [ 1, 2, 3, 4 ])
        == fromList [ 1, 3 ]

-}
removeWhen : (a -> Bool) -> Array a -> Array a
removeWhen isBad array =
    Array.filter (not << isBad) array


{-| Zip the elements of two arrays into tuples.

    zip [ 1, 2, 3 ] [ 'a', 'b' ]
        == [ ( 1, 'a' ), ( 2, 'b' ) ]

-}
zip : Array a -> Array b -> Array ( a, b )
zip =
    map2 Tuple.pair


{-| Zip the elements of three arrays into 3-tuples.

    zip3 [ 1, 2, 3 ] [ 'a', 'b' ] [ "a", "b", "c", "d" ]
        == [ ( 1, 'a', "b" ), ( 2, 'b', "b" ) ]

-}
zip3 : Array a -> Array b -> Array c -> Array ( a, b, c )
zip3 =
    map3 (\a b c -> ( a, b, c ))


{-| Unzip an array of tuples into a tuple containing two arrays for the values first & the second in the tuples.

    unzip (fromList [ ( 1, 'a' ), ( 2, 'b' ), ( 3, 'c' ) ])
        == ( fromList [ 1, 2, 3 ]
           , fromList [ 'a', 'b', 'c' ]
           )

-}
unzip : Array ( a, b ) -> ( Array a, Array b )
unzip tupleArray =
    ( tupleArray |> Array.map Tuple.first
    , tupleArray |> Array.map Tuple.second
    )


{-| Resize an array from the left, padding the right-hand side with the given value.

    resizelRepeat 4 0 (fromList [ 1, 2 ])
        == fromList [ 1, 2, 0, 0 ]

    resizelRepeat 2 0 (fromList [ 1, 2, 3 ])
        == fromList [ 1, 2 ]

    resizelRepeat -1 0 (fromList [ 1, 2 ])
        == empty

-}
resizelRepeat : Int -> a -> Array a -> Array a
resizelRepeat newLength defaultValue array =
    if newLength <= 0 then
        Array.empty

    else
        let
            len =
                length array
        in
        case compare len newLength of
            GT ->
                sliceUntil newLength array

            LT ->
                append array (repeat (newLength - len) defaultValue)

            EQ ->
                array


{-| Resize an array from the right, padding the left-hand side with the given value.

    resizerRepeat 4 0 (fromList [ 1, 2 ])
        == fromList [ 0, 0, 1, 2 ]

    resizerRepeat 2 0 (fromList [ 1, 2, 3 ])
        == fromList [ 2, 3 ]

    resizerRepeat -1 0 (fromList [ 1, 2 ])
        == empty

-}
resizerRepeat : Int -> a -> Array a -> Array a
resizerRepeat newLength defaultValue array =
    let
        len =
            length array
    in
    case compare len newLength of
        GT ->
            slice (len - newLength) len array

        LT ->
            append (repeat (newLength - len) defaultValue) array

        EQ ->
            array


{-| Resize an array from the left, padding the right-hand side with the given index function.

    resizelIndexed 5
        toLetterInAlphabet
        (fromList [ 'a', 'b', 'c' ])
        == fromList [ 'a', 'b', 'c', 'd', 'e' ]

    resizelIndexed 2
        toLetterInAlphabet
        (fromList [ 'a', 'b', 'c' ])
        == fromList [ 'a', 'b' ]

    resizelIndexed -1
        toLetterInAlphabet
        (fromList [ 'a', 'b', 'c' ])
        == empty

    toLetterInAlphabet : Int -> Char
    toLetterInAlphabet inAlphabet =
        (Char.toCode 'a') + inAlphabet
            |> Char.fromCode

-}
resizelIndexed : Int -> (Int -> a) -> Array a -> Array a
resizelIndexed newLength defaultValueAtIndex array =
    if newLength <= 0 then
        Array.empty

    else
        let
            len =
                length array
        in
        case compare len newLength of
            GT ->
                sliceUntil newLength array

            LT ->
                append array
                    (initialize (newLength - len)
                        (defaultValueAtIndex << (\i -> i + len))
                    )

            EQ ->
                array


{-| Resize an array from the right, padding the left-hand side with the given index function.

    resizerIndexed 5
        ((*) 5)
        (fromList [ 10, 25, 36 ])
        == fromList [ 0, 5, 10, 25, 36 ]

    resizerIndexed 2
        ((*) 5)
        (fromList [ 10, 25, 36 ])
        == fromList [ 25, 36 ]

    resizerIndexed -1
        ((*) 5)
        (fromList [ 10, 25, 36 ])
        == empty

-}
resizerIndexed : Int -> (Int -> a) -> Array a -> Array a
resizerIndexed newLength defaultValueAtIndex array =
    let
        len =
            length array
    in
    case compare len newLength of
        GT ->
            slice (len - newLength) len array

        LT ->
            append
                (initialize (newLength - len) defaultValueAtIndex)
                array

        EQ ->
            array


{-| Reverse an array.

    reverse (fromList [ 1, 2, 3, 4 ])
        == fromList [ 4, 3, 2, 1 ]

-}
reverse : Array a -> Array a
reverse xs =
    xs
        |> Array.toList
        |> List.reverse
        |> Array.fromList


{-| Split an array into two arrays, the first ending at and the second starting at the given index.

    splitAt 2 (fromList [ 1, 2, 3, 4 ])
        == ( fromList [ 1, 2 ], fromList [ 3, 4 ] )

    splitAt 100 (fromList [ 1, 2, 3, 4 ])
        == ( fromList [ 1, 2, 3, 4 ], empty )

    splitAt -1 (fromList [ 1, 2, 3, 4 ])
        == ( empty, fromList [ 1, 2, 3, 4 ] )

-}
splitAt : Int -> Array a -> ( Array a, Array a )
splitAt index array =
    if index > 0 then
        ( sliceUntil index array
        , sliceFrom index array
        )

    else
        ( empty, array )


{-| Remove the element at the given index.

    removeAt 2 (fromList [ 1, 2, 3, 4 ])
        == fromList [ 1, 2, 4 ]

    removeAt -1 (fromList [ 1, 2, 3, 4 ])
        == fromList [ 1, 2, 3, 4 ]

    removeAt 100 (fromList [ 1, 2, 3, 4 ])
        == fromList [ 1, 2, 3, 4 ]

-}
removeAt : Int -> Array a -> Array a
removeAt index array =
    if index >= 0 then
        let
            ( beforeIndex, startingAtIndex ) =
                splitAt index array

            lengthStartingAtIndex =
                length startingAtIndex
        in
        if lengthStartingAtIndex == 0 then
            beforeIndex

        else
            append beforeIndex
                (slice 1 lengthStartingAtIndex startingAtIndex)

    else
        array


{-| Insert an element at the given index.

    insertAt 1 'b' (fromList [ 'a', 'c' ])
        == fromList [ 'a', 'b', 'c' ]

    insertAt -1 'b' (fromList [ 'a', 'c' ])
        == fromList [ 'a', 'c' ]

    insertAt 100 'b' (fromList [ 'a', 'c' ])
        == fromList [ 'a', 'c' ]

-}
insertAt : Int -> a -> Array a -> Array a
insertAt index val values =
    let
        length =
            Array.length values
    in
    if index >= 0 && index <= length then
        let
            before =
                Array.slice 0 index values

            after =
                Array.slice index length values
        in
        Array.append (Array.push val before) after

    else
        values
