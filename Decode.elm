module Decode exposing (model, origin, destination, startOrigin, startDestination, initial, defaultRotation)

import Json.Decode as Decode exposing (Value, Decoder)
import Types exposing (..)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (Vec3)
import Math.Vector4 as Vec4 exposing (Vec4)
import Utils exposing (..)
import Window
import Quaternion


startOrigin : Vec3
startOrigin =
    Vec3.vec3 0 1 -18


startDestination : Vec3
startDestination =
    Vec3.vec3 0 -2 0


origin : Vec3
origin =
    Vec3.vec3 0 0 -11


destination : Vec3
destination =
    Vec3.vec3 0 0 0


model : Decoder Model
model =
    Decode.map5
        (\width height devicePixelRatio rotation cubik ->
            { initial
                | rotation = rotation
                , window = Window.Size width height
                , devicePixelRatio = devicePixelRatio
                , cubik = cubik
                , state = WaitForUserInput
            }
        )
        (Decode.field "width" Decode.int)
        (Decode.field "height" Decode.int)
        (Decode.field "devicePixelRatio" Decode.float)
        (Decode.field "rotation" vec4)
        (Decode.field "cubik" (Decode.list cell))


initial : Model
initial =
    { state = Initial
    , rotation = defaultRotation
    , window = Window.Size 0 0
    , devicePixelRatio = 2
    , cubik = defaultCubik
    , time = 0
    , font = Nothing
    }


cell : Decoder Cell
cell =
    Decode.map3 Cell
        (Decode.field "transform" mat4)
        (Decode.field "color" color)
        (Decode.field "normal" vec3)


color : Decoder Color
color =
    Decode.andThen
        (\c ->
            case c of
                "red" ->
                    Decode.succeed Red

                "white" ->
                    Decode.succeed White

                "blue" ->
                    Decode.succeed Blue

                "orange" ->
                    Decode.succeed Orange

                "yellow" ->
                    Decode.succeed Yellow

                "green" ->
                    Decode.succeed Green

                c ->
                    Decode.fail ("Unknown color: " ++ c)
        )
        Decode.string


vec3 : Decoder Vec3
vec3 =
    Decode.andThen
        (\l ->
            case l of
                [ x, y, z ] ->
                    Decode.succeed (Vec3.vec3 x y z)

                _ ->
                    Decode.fail "Wrong number of vector components"
        )
        (Decode.list Decode.float)


vec4 : Decoder Vec4
vec4 =
    Decode.andThen
        (\l ->
            case l of
                [ x, y, z, w ] ->
                    Decode.succeed (Vec4.vec4 x y z w)

                _ ->
                    Decode.fail "Wrong number of vector components"
        )
        (Decode.list Decode.float)


mat4 : Decoder Mat4
mat4 =
    Decode.andThen
        (\l ->
            case l of
                [ m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44 ] ->
                    { m11 = m11, m21 = m21, m31 = m31, m41 = m41, m12 = m12, m22 = m22, m32 = m32, m42 = m42, m13 = m13, m23 = m23, m33 = m33, m43 = m43, m14 = m14, m24 = m24, m34 = m34, m44 = m44 }
                        |> Mat4.fromRecord
                        |> Decode.succeed

                _ ->
                    Decode.fail "Wrong number of matrix components"
        )
        (Decode.list Decode.float)


defaultRotation : Vec4
defaultRotation =
    Quaternion.identity
        |> Quaternion.mul (Quaternion.fromAngleAxis (pi / 4) Vec3.j)
        |> Quaternion.mul (Quaternion.fromAngleAxis (-0.95531661779) Vec3.i)


defaultCubik : List Cell
defaultCubik =
    List.concatMap makeSide [ Red, Green, White, Blue, Orange, Yellow ]


makeSide : Color -> List Cell
makeSide color =
    case color of
        Green ->
            frontFace color

        Blue ->
            List.map (rotateCell XAxis pi) (frontFace color)

        White ->
            List.map (rotateCell XAxis (pi / 2)) (frontFace color)

        Yellow ->
            List.map (rotateCell XAxis (-pi / 2)) (frontFace color)

        Orange ->
            List.map (rotateCell YAxis (-pi / 2)) (frontFace color)

        Red ->
            List.map (rotateCell YAxis (pi / 2)) (frontFace color)


frontFace : Color -> List Cell
frontFace color =
    List.range -1 1
        |> List.concatMap
            (\x ->
                List.map
                    (\y -> Cell (Mat4.makeTranslate3 (toFloat x) (toFloat y) -1) color (Vec3.vec3 0 0 -1))
                    (List.range -1 1)
            )
