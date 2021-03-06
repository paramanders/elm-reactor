module SideBar where

import Graphics.Element exposing (..)
import Html
import List
import Window

import SideBar.Controls as Controls
import SideBar.Model as Model
import SideBar.Watches as Watches


view : (Int, Int) -> List (String, String) -> Bool -> Model.Model -> Element
view (w,h) watches permitSwap state =
  let controls =
          Controls.view (w, h) showSwap permitSwap state

      watchView =
          Html.toElement w (h - 150) (Watches.view watches)
  in
      flow down
        [ controls
        , watchView
        ]


-- SIGNALS    

main : Signal Element
main =
  Signal.map4 view
    (Signal.map (\(w,h) -> (Controls.panelWidth, h)) Window.dimensions)
    watches
    permitSwapMailbox.signal
    scene


scene : Signal Model.Model
scene =
  Signal.foldp Model.update Model.startModel aggregateUpdates


aggregateUpdates : Signal Model.Action
aggregateUpdates =
  Signal.mergeMany
    [ Signal.map (always Model.Restart) restartMailbox.signal
    , Signal.map Model.Pause pausedInputMailbox.signal
    , Signal.map Model.TotalEvents eventCounter
    , Signal.map Model.ScrubPosition scrubMailbox.signal
    ]

-- CONTROL MAILBOXES

permitSwapMailbox = Controls.permitSwapMailbox

restartMailbox = Controls.restartMailbox

pausedInputMailbox = Controls.pausedInputMailbox

scrubMailbox = Controls.scrubMailbox

-- INCOMING PORTS

port eventCounter : Signal Int

port watches : Signal (List (String, String))

port showSwap : Bool


-- OUTGOING PORTS

port scrubTo : Signal Int
port scrubTo =
    scrubMailbox.signal


port pause : Signal Bool
port pause =
    pausedInputMailbox.signal


port restart : Signal Int
port restart =
    Signal.map (always 0) restartMailbox.signal


port permitSwap : Signal Bool
port permitSwap =
    permitSwapMailbox.signal
