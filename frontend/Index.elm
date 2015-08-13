module Index where

import Color exposing (Color, darkGrey)
import Dict
import FontAwesome as FA
import Html exposing (..)
import Html.Attributes exposing (..)
import Markdown
import Signal exposing (Signal, Address)
import String
import Util exposing (..)


-- MAIN

main : Html
main =
  view info


port info : Model


-- MODEL

type alias Model =
    { pwd : List String
    , dirs : List String
    , files : List String
    , pkg : Maybe PackageInfo
    , readme : Maybe String
    }


type alias PackageInfo =
    { version : String
    , repository : String
    , summary : String
    , dependencies : List (String, String)
    }


-- CONSTANTS

(=>) = (,)


pageWidth = "960px"
smallBoxWidth = "300px"
largeBoxWidth = "600px"


floatLeft =
  [ "float" => "left" ]


floatRight =
  [ "float" => "right" ]


boxStyles =
  [ "border" => "1px solid #c7c7c7"
  , "border-radius" => "5px"
  ]


boxHeaderStyles =
  [ "background-color" => "#fafafa"
  , "text-align" => "center"
  ]


blockStyles =
  [ "display" => "block"
  , "overflow" => "hidden"
  , "padding" => "7px 12px"
  ]


boxItemStyles =
  [ "border-top" => "1px solid #e1e1e1" ]


linkStyles =
  [ "color" => "#1184ce"
  , "text-decoration" => "none"
  ]


clearfix : Html
clearfix =
  div [ style [ "clear" => "both" ] ] []


-- VIEW

view : Model -> Html
view model =
  let
    packageDependants pkgInfo =
      [ div
          [ style ("width" => smallBoxWidth :: floatRight)
          ]
          [ viewPackageInfo pkgInfo
          , dependenciesView pkgInfo.dependencies
          ]
      ]

    contents =
      navigator model.pwd
      :: folderView model
      :: Maybe.withDefault [] (Maybe.map packageDependants model.pkg)
      ++ [ clearfix ]
  in
    div
      [ style
          [ "font-family" => """"Open Sans", "Arial", sans-serif"""
          , "margin" => "0"
          , "padding" => "0"
          , "background-color" => "white"
          ]
      ]
      [ pageHeader model
      , div
          [ style
              [ "width" => pageWidth
              , "margin-left" => "auto"
              , "margin-right" => "auto"
              ]
          ]
          contents
      ]



pageHeader : Model -> Html
pageHeader model =
  header
    [ style
        [ "width" => "100%"
        , "background-color" => "#1184ce"
        , "height" => "8px"
        ]
    ]
    []


folderView : Model -> Html
folderView model =
  let
    files =
      div
        [ style (boxStyles ++ ["margin-bottom" => "30px"]) ]
        (
          div [ style <| boxHeaderStyles ++ blockStyles ] [ text "File Navigation" ]
          :: List.map folderDisplay (List.sort model.dirs)
          ++ List.map fileDisplay (List.sort model.files)
        )

    viewReadme markdown =
      [ div
          [ style boxStyles ]
          [ div [ style <| boxHeaderStyles ++ blockStyles ] [ text "README" ]
          , div [ style ["padding" => "20px"] ] [ Markdown.toHtml markdown ]
          ]
      ]
  in
    section
      [ style (floatLeft ++ ["width" => largeBoxWidth])
      ]
      (files :: Maybe.withDefault [] (Maybe.map viewReadme model.readme))


folderDisplay : String -> Html
folderDisplay folder =
  a [ href folder
    , style (linkStyles ++ blockStyles ++ boxItemStyles)
    ]
    [ folderIcon, text folder
    ]


elmFileLinks : Bool -> String -> List Html
elmFileLinks isElmFile file =
  let
    jumpLinkStyle =
      linkStyles ++ floatRight ++
        [ "padding" => "0 5px"
        , "color" => "#c7c7c7"
        ]
  in
    if isElmFile then
      [ a [ href (file ++ "?debug"), style jumpLinkStyle ]
          [ text "Debug" ]
      ]
    else
      []


fileDisplay : String -> Html
fileDisplay file =
  let
    isElmFile = String.endsWith ".elm" file
  in
    div
      [ style <| blockStyles ++ boxItemStyles ]
      <| [ a
        [ href <| file
        , style linkStyles
        ]
        [ getIcon file
        , span [ style [ "display" => "inline-block"
                       , "width" => if isElmFile then "75%" else "90%"
                       ]
               ] [ text file ]
        ]
      ] ++ (elmFileLinks isElmFile file)


navigator : List String -> Html
navigator pathSegments =
  let
    hrefs =
      List.scanl (\sub path -> path </> sub) "" ("" :: pathSegments)
        |> List.drop 1

    names =
      FA.home darkGrey 32 :: List.map text pathSegments

    toLink name path =
      a [ href path, style linkStyles ] [ name ]

    subfolders =
      List.map2 toLink names hrefs
  in
    div
      [ style [ "font-size" => "2em", "padding" => "20px 0", "display" => "flex", "align-items" => "center", "height" => "40px" ] ]
      (List.intersperse navigatorSeparator subfolders)


navigatorSeparator =
  span [ style [ "padding" => "0 8px" ] ] [ text "/" ]


-- DEPENDENCIES

packageUrl : String -> String -> String
packageUrl name version =
  "http://package.elm-lang.org/packages" </> name </> version


dependenciesView : List (String, String) -> Html
dependenciesView dependencies =
  div
    [ style (boxStyles ++ floatRight ++ [ "width" => smallBoxWidth ])
    ]
    ( div
        [ style (boxHeaderStyles ++ blockStyles)
        ]
        [ text "Dependencies" ]
      :: List.map dependencyView dependencies
    )


dependencyView : (String, String) -> Html
dependencyView (name, version) =
  div
    [ style (blockStyles ++ boxItemStyles)
    ]
    [ div
        [ style floatLeft ]
        [ packageIcon
        , a [ href (packageUrl name version)
            , style linkStyles
            ]
            [ text name ]
        ]
    , div
        [ style floatRight ]
        [ text version ]
    ]


--

viewPackageInfo : PackageInfo -> Html
viewPackageInfo pkgInfo =
  div
    [ style <| boxStyles ++ floatRight ++
        [ "margin-bottom" => "30px"
        , "width" => smallBoxWidth
        ]
    ]
    [ div [ style <| boxHeaderStyles ++ blockStyles ] [ text "Package Information" ]
    , div [ style <| blockStyles ++ boxItemStyles ] [ text pkgInfo.summary ]
    , div [ style <| blockStyles ++ boxItemStyles ] [ text <| "Version: " ++ pkgInfo.version ]
    ]


-- ICONS

getIcon : String -> Html
getIcon filename =
  let
    file = String.toLower filename
  in
    Dict.get (takeExtension file) endings
      |> Maybe.withDefault fileIcon


endings =
  Dict.fromList
    [ "jpg"  => imageIcon
    , "jpeg" => imageIcon
    , "png"  => imageIcon
    , "gif"  => imageIcon
    ]


imageIcon =
  makeIcon FA.file_image_o


fileIcon =
  makeIcon FA.file_text_o


folderIcon =
  makeIcon FA.folder


packageIcon =
  makeIcon FA.archive


makeIcon : (Color -> Int -> Html) -> Html
makeIcon icon =
  span
    [ style [ "display" => "inline-block", "vertical-align" => "middle", "padding-right" => "0.5em" ] ]
    [ icon darkGrey 16 ]
