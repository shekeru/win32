-----------------------------------------------------------------------------
-- |
-- Module      :  Graphics.Win32.Window
-- Copyright   :  (c) Alastair Reid, 1997-2003
-- License     :  BSD-style (see the file libraries/base/LICENSE)
--
-- Maintainer  :  libraries@haskell.org
-- Stability   :  provisional
-- Portability :  portable
--
-- A collection of FFI declarations for interfacing with Win32.
--
-----------------------------------------------------------------------------

module Graphics.Win32.Window where

import System.Win32.Types
import Graphics.Win32.GDI.Types
import Graphics.Win32.Message

import Control.Monad
import Foreign

#include <windows.h>

----------------------------------------------------------------
-- Window Class
----------------------------------------------------------------

-- The classname must not be deallocated until the corresponding class
-- is deallocated.  For this reason, we represent classnames by pointers
-- and explicitly allocate the className.

type ClassName   = LPCTSTR

-- Note: this is one of those rare functions which doesnt free all
-- its String arguments.

mkClassName :: String -> ClassName
mkClassName name = unsafePerformIO (newTString name)

type ClassStyle   = UINT

#{enum ClassStyle,
 , cS_VREDRAW           = CS_VREDRAW
 , cS_HREDRAW           = CS_HREDRAW
 , cS_OWNDC             = CS_OWNDC
 , cS_CLASSDC           = CS_CLASSDC
 , cS_PARENTDC          = CS_PARENTDC
 , cS_SAVEBITS          = CS_SAVEBITS
 , cS_DBLCLKS           = CS_DBLCLKS
 , cS_BYTEALIGNCLIENT   = CS_BYTEALIGNCLIENT
 , cS_BYTEALIGNWINDOW   = CS_BYTEALIGNWINDOW
 , cS_NOCLOSE           = CS_NOCLOSE
 , cS_GLOBALCLASS       = CS_GLOBALCLASS
 }

type WNDCLASS =
 (ClassStyle,    -- style
  HINSTANCE,     -- hInstance
  Maybe HICON,   -- hIcon
  Maybe HCURSOR, -- hCursor
  Maybe HBRUSH,  -- hbrBackground
  Maybe LPCSTR,  -- lpszMenuName
  ClassName)     -- lpszClassName

--ToDo!
--To avoid confusion with NULL, WNDCLASS requires you to add 1 to a SystemColor
--(which can be NULL)
-- %fun mkMbHBRUSH :: SystemColor -> MbHBRUSH
-- %code
-- %result ((HBRUSH)($0+1));

withWNDCLASS :: WNDCLASS -> (Ptr WNDCLASS -> IO a) -> IO a
withWNDCLASS (style, inst, mb_icon, mb_cursor, mb_bg, mb_menu, cls) f =
  allocaBytes #{size WNDCLASS} $ \ p -> do
  #{poke WNDCLASS,style} p style
  #{poke WNDCLASS,lpfnWndProc} p genericWndProc_p
  #{poke WNDCLASS,cbClsExtra} p (0::Int)
  #{poke WNDCLASS,cbWndExtra} p (0::Int)
  #{poke WNDCLASS,hInstance} p inst
  #{poke WNDCLASS,hIcon} p (maybePtr mb_icon)
  #{poke WNDCLASS,hCursor} p (maybePtr mb_cursor)
  #{poke WNDCLASS,hbrBackground} p (maybePtr mb_bg)
  #{poke WNDCLASS,lpszMenuName} p (maybePtr mb_menu)
  #{poke WNDCLASS,lpszClassName} p cls
  f p

foreign import ccall unsafe "WndProc.h &genericWndProc"
  genericWndProc_p :: FunPtr WindowClosure

{-# CBITS WndProc.c #-}

registerClass :: WNDCLASS -> IO (Maybe ATOM)
registerClass cls =
  withWNDCLASS cls $ \ p ->
  liftM numToMaybe $ c_RegisterClass p
foreign import ccall unsafe "windows.h RegisterClassW"
  c_RegisterClass :: Ptr WNDCLASS -> IO ATOM

foreign import ccall unsafe "windows.h UnregisterClassW"
  unregisterClass :: ClassName -> HINSTANCE -> IO ()

----------------------------------------------------------------
-- Window Style
----------------------------------------------------------------

type WindowStyle   = DWORD

#{enum WindowStyle,
 , wS_OVERLAPPED        = WS_OVERLAPPED
 , wS_POPUP             = WS_POPUP
 , wS_CHILD             = WS_CHILD
 , wS_CLIPSIBLINGS      = WS_CLIPSIBLINGS
 , wS_CLIPCHILDREN      = WS_CLIPCHILDREN
 , wS_VISIBLE           = WS_VISIBLE
 , wS_DISABLED          = WS_DISABLED
 , wS_MINIMIZE          = WS_MINIMIZE
 , wS_MAXIMIZE          = WS_MAXIMIZE
 , wS_CAPTION           = WS_CAPTION
 , wS_BORDER            = WS_BORDER
 , wS_DLGFRAME          = WS_DLGFRAME
 , wS_VSCROLL           = WS_VSCROLL
 , wS_HSCROLL           = WS_HSCROLL
 , wS_SYSMENU           = WS_SYSMENU
 , wS_THICKFRAME        = WS_THICKFRAME
 , wS_MINIMIZEBOX       = WS_MINIMIZEBOX
 , wS_MAXIMIZEBOX       = WS_MAXIMIZEBOX
 , wS_GROUP             = WS_GROUP
 , wS_TABSTOP           = WS_TABSTOP
 , wS_OVERLAPPEDWINDOW  = WS_OVERLAPPEDWINDOW
 , wS_POPUPWINDOW       = WS_POPUPWINDOW
 , wS_CHILDWINDOW       = WS_CHILDWINDOW
 , wS_TILED             = WS_TILED
 , wS_ICONIC            = WS_ICONIC
 , wS_SIZEBOX           = WS_SIZEBOX
 , wS_TILEDWINDOW       = WS_TILEDWINDOW
 }

type WindowStyleEx   = DWORD

#{enum WindowStyleEx,
 , wS_EX_DLGMODALFRAME  = WS_EX_DLGMODALFRAME
 , wS_EX_NOPARENTNOTIFY = WS_EX_NOPARENTNOTIFY
 , wS_EX_TOPMOST        = WS_EX_TOPMOST
 , wS_EX_ACCEPTFILES    = WS_EX_ACCEPTFILES
 , wS_EX_TRANSPARENT    = WS_EX_TRANSPARENT
 , wS_EX_MDICHILD       = WS_EX_MDICHILD
 , wS_EX_TOOLWINDOW     = WS_EX_TOOLWINDOW
 , wS_EX_WINDOWEDGE     = WS_EX_WINDOWEDGE
 , wS_EX_CLIENTEDGE     = WS_EX_CLIENTEDGE
 , wS_EX_CONTEXTHELP    = WS_EX_CONTEXTHELP
 , wS_EX_RIGHT          = WS_EX_RIGHT
 , wS_EX_LEFT           = WS_EX_LEFT
 , wS_EX_RTLREADING     = WS_EX_RTLREADING
 , wS_EX_LTRREADING     = WS_EX_LTRREADING
 , wS_EX_LEFTSCROLLBAR  = WS_EX_LEFTSCROLLBAR
 , wS_EX_RIGHTSCROLLBAR = WS_EX_RIGHTSCROLLBAR
 , wS_EX_CONTROLPARENT  = WS_EX_CONTROLPARENT
 , wS_EX_STATICEDGE     = WS_EX_STATICEDGE
 , wS_EX_APPWINDOW      = WS_EX_APPWINDOW
 , wS_EX_OVERLAPPEDWINDOW = WS_EX_OVERLAPPEDWINDOW
 , wS_EX_PALETTEWINDOW  = WS_EX_PALETTEWINDOW
 }

cW_USEDEFAULT :: Pos
cW_USEDEFAULT = #{const CW_USEDEFAULT}

type Pos = Int

type MbPos = Maybe Pos

maybePos :: Maybe Pos -> Pos
maybePos = maybe cW_USEDEFAULT id

type WindowClosure = HWND -> WindowMessage -> WPARAM -> LPARAM -> IO LRESULT

foreign import ccall "wrapper"
  mkWindowClosure :: WindowClosure -> IO (FunPtr WindowClosure)

setWindowClosure :: HWND -> WindowClosure -> IO ()
setWindowClosure wnd closure = do
  fp <- mkWindowClosure closure
  c_SetWindowLong wnd (#{const GWL_USERDATA}) (castFunPtrToLONG fp)
  return ()
foreign import ccall unsafe "windows.h SetWindowLongW"
  c_SetWindowLong :: HWND -> Int -> LONG -> IO LONG

createWindow
  :: ClassName -> String -> WindowStyle ->
     Maybe Pos -> Maybe Pos -> Maybe Pos -> Maybe Pos ->
     Maybe HWND -> Maybe HMENU -> HINSTANCE -> WindowClosure ->
     IO HWND
createWindow cname wname style mb_x mb_y mb_w mb_h mb_parent mb_menu inst closure =
  withTString wname $ \ c_wname -> do
  wnd <- failIfNull "CreateWindow" $
    c_CreateWindow cname c_wname style
      (maybePos mb_x) (maybePos mb_y) (maybePos mb_w) (maybePos mb_h)
      (maybePtr mb_parent) (maybePtr mb_menu) inst nullPtr
  setWindowClosure wnd closure
  return wnd
foreign import ccall unsafe "windows.h CreateWindowW"
  c_CreateWindow
    :: ClassName -> LPCTSTR -> WindowStyle ->
       Pos -> Pos -> Pos -> Pos ->
       HWND -> HMENU -> HINSTANCE -> LPVOID ->
       IO HWND

-- Freeing the title/window name has been reported
-- to cause a crash, so let's not do it.
-- %end free(windowName)  /* I think this is safe... */

createWindowEx
  :: WindowStyle -> ClassName -> String -> WindowStyle
  -> Maybe Pos -> Maybe Pos -> Maybe Pos -> Maybe Pos
  -> Maybe HWND -> Maybe HMENU -> HINSTANCE -> WindowClosure
  -> IO HWND
createWindowEx estyle cname wname wstyle mb_x mb_y mb_w mb_h mb_parent mb_menu inst closure =
  withTString wname $ \ c_wname -> do
  wnd <- failIfNull "CreateWindowEx" $
    c_CreateWindowEx estyle cname c_wname wstyle
      (maybePos mb_x) (maybePos mb_y) (maybePos mb_w) (maybePos mb_h)
      (maybePtr mb_parent) (maybePtr mb_menu) inst nullPtr
  setWindowClosure wnd closure
  return wnd
foreign import ccall unsafe "windows.h CreateWindowExW"
  c_CreateWindowEx
    :: WindowStyle -> ClassName -> LPCTSTR -> WindowStyle
    -> Pos -> Pos -> Pos -> Pos
    -> HWND -> HMENU -> HINSTANCE -> LPVOID
    -> IO HWND

-- see CreateWindow comment.
-- %end free(wname)  /* I think this is safe... */

----------------------------------------------------------------

defWindowProc :: Maybe HWND -> WindowMessage -> WPARAM -> LPARAM -> IO LRESULT
defWindowProc mb_wnd msg w l =
  c_DefWindowProc (maybePtr mb_wnd) msg w l
foreign import ccall unsafe "windows.h DefWindowProcW"
  c_DefWindowProc :: HWND -> WindowMessage -> WPARAM -> LPARAM -> IO LRESULT

----------------------------------------------------------------

getClientRect :: HWND -> IO RECT
getClientRect wnd =
  allocaRECT $ \ p_rect -> do
  failIfFalse_ "GetClientRect" $ c_GetClientRect wnd p_rect
  peekRECT p_rect
foreign import ccall unsafe "windows.h GetClientRect"
  c_GetClientRect :: HWND -> Ptr RECT -> IO Bool

getWindowRect :: HWND -> IO RECT
getWindowRect wnd =
  allocaRECT $ \ p_rect -> do
  failIfFalse_ "GetWindowRect" $ c_GetWindowRect wnd p_rect
  peekRECT p_rect
foreign import ccall unsafe "windows.h GetWindowRect"
  c_GetWindowRect :: HWND -> Ptr RECT -> IO Bool

-- Should it be Maybe RECT instead?

invalidateRect :: Maybe HWND -> Maybe LPRECT -> Bool -> IO ()
invalidateRect wnd p_mb_rect erase =
  failIfFalse_ "InvalidateRect" $
    c_InvalidateRect (maybePtr wnd) (maybePtr p_mb_rect) erase
foreign import ccall unsafe "windows.h InvalidateRect"
  c_InvalidateRect :: HWND -> LPRECT -> Bool -> IO Bool

screenToClient :: HWND -> POINT -> IO POINT
screenToClient wnd pt =
  withPOINT pt $ \ p_pt -> do
  failIfFalse_ "ScreenToClient" $ c_ScreenToClient wnd p_pt
  peekPOINT p_pt
foreign import ccall unsafe "windows.h ScreenToClient"
  c_ScreenToClient :: HWND -> Ptr POINT -> IO Bool

clientToScreen :: HWND -> POINT -> IO POINT
clientToScreen wnd pt =
  withPOINT pt $ \ p_pt -> do
  failIfFalse_ "ClientToScreen" $ c_ClientToScreen wnd p_pt
  peekPOINT p_pt
foreign import ccall unsafe "windows.h ClientToScreen"
  c_ClientToScreen :: HWND -> Ptr POINT -> IO Bool

----------------------------------------------------------------
-- Setting window text/label
----------------------------------------------------------------
-- For setting the title bar text.  But inconvenient to make the LPCTSTR

setWindowText :: HWND -> String -> IO ()
setWindowText wnd text =
  withTString text $ \ c_text ->
  failIfFalse_ "SetWindowText" $ c_SetWindowText wnd c_text
foreign import ccall unsafe "windows.h SetWindowTextW"
  c_SetWindowText :: HWND -> LPCTSTR -> IO Bool

----------------------------------------------------------------
-- Paint struct
----------------------------------------------------------------

type PAINTSTRUCT =
 ( HDC   -- hdc
 , Bool  -- fErase
 , RECT  -- rcPaint
 )

type LPPAINTSTRUCT   = Addr

sizeofPAINTSTRUCT :: DWORD
sizeofPAINTSTRUCT = #{size PAINTSTRUCT}

beginPaint :: HWND -> LPPAINTSTRUCT -> IO HDC
beginPaint wnd paint =
  failIfNull "BeginPaint" $ c_BeginPaint wnd paint
foreign import ccall unsafe "windows.h BeginPaint"
  c_BeginPaint :: HWND -> LPPAINTSTRUCT -> IO HDC

foreign import ccall unsafe "windows.h EndPaint"
  endPaint :: HWND -> LPPAINTSTRUCT -> IO ()
-- Apparently always succeeds (return non-zero)

----------------------------------------------------------------
-- ShowWindow
----------------------------------------------------------------

type ShowWindowControl   = DWORD

#{enum ShowWindowControl,
 , sW_HIDE              = SW_HIDE
 , sW_SHOWNORMAL        = SW_SHOWNORMAL
 , sW_SHOWMINIMIZED     = SW_SHOWMINIMIZED
 , sW_SHOWMAXIMIZED     = SW_SHOWMAXIMIZED
 , sW_MAXIMIZE          = SW_MAXIMIZE
 , sW_SHOWNOACTIVATE    = SW_SHOWNOACTIVATE
 , sW_SHOW              = SW_SHOW
 , sW_MINIMIZE          = SW_MINIMIZE
 , sW_SHOWMINNOACTIVE   = SW_SHOWMINNOACTIVE
 , sW_SHOWNA            = SW_SHOWNA
 , sW_RESTORE           = SW_RESTORE
 }

foreign import ccall unsafe "windows.h ShowWindow"
  showWindow :: HWND  -> ShowWindowControl  -> IO Bool

----------------------------------------------------------------
-- Misc
----------------------------------------------------------------

adjustWindowRect :: RECT -> WindowStyle -> Bool -> IO RECT
adjustWindowRect rect style menu =
  withRECT rect $ \ p_rect -> do
  failIfFalse_ "AdjustWindowRect" $ c_AdjustWindowRect p_rect style menu
  peekRECT p_rect
foreign import ccall unsafe "windows.h AdjustWindowRect"
  c_AdjustWindowRect :: Ptr RECT -> WindowStyle -> Bool -> IO Bool

adjustWindowRectEx :: RECT -> WindowStyle -> Bool -> WindowStyleEx -> IO RECT
adjustWindowRectEx rect style menu exstyle =
  withRECT rect $ \ p_rect -> do
  failIfFalse_ "AdjustWindowRectEx" $
    c_AdjustWindowRectEx p_rect style menu exstyle
  peekRECT p_rect
foreign import ccall unsafe "windows.h AdjustWindowRectEx"
  c_AdjustWindowRectEx :: Ptr RECT -> WindowStyle -> Bool -> WindowStyleEx -> IO Bool

-- Win2K and later:
-- %fun AllowSetForegroundWindow :: DWORD -> IO ()

-- %
-- %dis animateWindowType x = dWORD x
-- type AnimateWindowType   = DWORD

-- %const AnimateWindowType
--        [ AW_SLIDE
--        , AW_ACTIVATE
--        , AW_BLEND
--        , AW_HIDE
--        , AW_CENTER
--        , AW_HOR_POSITIVE
--        , AW_HOR_NEGATIVE
--        , AW_VER_POSITIVE
--        , AW_VER_NEGATIVE
--        ]

-- Win98 or Win2K:
-- %fun AnimateWindow :: HWND -> DWORD -> AnimateWindowType -> IO ()
-- %code BOOL success = AnimateWindow(arg1,arg2,arg3)
-- %fail { !success } { ErrorWin("AnimateWindow") }

foreign import ccall unsafe "windows.h AnyPopup"
  anyPopup :: IO Bool

arrangeIconicWindows :: HWND -> IO ()
arrangeIconicWindows wnd =
  failIfFalse_ "ArrangeIconicWindows" $ c_ArrangeIconicWindows wnd
foreign import ccall unsafe "windows.h ArrangeIconicWindows"
  c_ArrangeIconicWindows :: HWND -> IO Bool

beginDeferWindowPos :: Int -> IO HDWP
beginDeferWindowPos n =
  failIfNull "BeginDeferWindowPos" $ c_BeginDeferWindowPos n
foreign import ccall unsafe "windows.h BeginDeferWindowPos"
  c_BeginDeferWindowPos :: Int -> IO HDWP

bringWindowToTop :: HWND -> IO ()
bringWindowToTop wnd =
  failIfFalse_ "BringWindowToTop" $ c_BringWindowToTop wnd
foreign import ccall unsafe "windows.h BringWindowToTop"
  c_BringWindowToTop :: HWND -> IO Bool

-- Can't pass structs with current FFI, so use a C wrapper
childWindowFromPoint :: HWND -> POINT -> IO (Maybe HWND)
childWindowFromPoint wnd pt =
  withPOINT pt $ \ p_pt ->
  liftM ptrToMaybe $ prim_ChildWindowFromPoint wnd p_pt
foreign import ccall unsafe "HsWin32.h"
  prim_ChildWindowFromPoint :: HWND -> Ptr POINT -> IO HWND

-- Can't pass structs with current FFI, so use a C wrapper
childWindowFromPointEx :: HWND -> POINT -> DWORD -> IO (Maybe HWND)
childWindowFromPointEx parent pt flags =
  withPOINT pt $ \ p_pt ->
  liftM ptrToMaybe $ prim_ChildWindowFromPointEx parent p_pt flags
foreign import ccall unsafe "HsWin32.h"
  prim_ChildWindowFromPointEx :: HWND -> Ptr POINT -> DWORD -> IO HWND

closeWindow :: HWND -> IO ()
closeWindow wnd =
  failIfFalse_ "CloseWindow" $ c_CloseWindow wnd
foreign import ccall unsafe "windows.h DestroyWindow"
  c_CloseWindow :: HWND -> IO Bool

deferWindowPos :: HDWP -> HWND -> HWND -> Int -> Int -> Int -> Int -> SetWindowPosFlags -> IO HDWP
deferWindowPos wp wnd after x y cx cy flags =
  failIfNull "DeferWindowPos" $ c_DeferWindowPos wp wnd after x y cx cy flags
foreign import ccall unsafe "windows.h DeferWindowPos"
  c_DeferWindowPos :: HDWP -> HWND -> HWND -> Int -> Int -> Int -> Int -> SetWindowPosFlags -> IO HDWP

destroyWindow :: HWND -> IO ()
destroyWindow wnd =
  failIfFalse_ "DestroyWindow" $ c_DestroyWindow wnd
foreign import ccall unsafe "windows.h DestroyWindow"
  c_DestroyWindow :: HWND -> IO Bool

endDeferWindowPos :: HDWP -> IO ()
endDeferWindowPos pos =
  failIfFalse_ "EndDeferWindowPos" $ c_EndDeferWindowPos pos
foreign import ccall unsafe "windows.h EndDeferWindowPos"
  c_EndDeferWindowPos :: HDWP -> IO Bool

findWindow :: String -> String -> IO (Maybe HWND)
findWindow cname wname =
  withTString cname $ \ c_cname ->
  withTString wname $ \ c_wname ->
  liftM ptrToMaybe $ c_FindWindow c_cname c_wname
foreign import ccall unsafe "windows.h FindWindowW"
  c_FindWindow :: LPCTSTR -> LPCTSTR -> IO HWND

findWindowEx :: HWND -> HWND -> String -> String -> IO (Maybe HWND)
findWindowEx parent after cname wname =
  withTString cname $ \ c_cname ->
  withTString wname $ \ c_wname ->
  liftM ptrToMaybe $ c_FindWindowEx parent after c_cname c_wname
foreign import ccall unsafe "windows.h FindWindowExW"
  c_FindWindowEx :: HWND -> HWND -> LPCTSTR -> LPCTSTR -> IO HWND

foreign import ccall unsafe "windows.h FlashWindow"
  flashWindow :: HWND -> Bool -> IO Bool
-- No error code

moveWindow :: HWND -> Int -> Int -> Int -> Int -> Bool -> IO ()
moveWindow wnd x y w h repaint =
  failIfFalse_ "MoveWindow" $ c_MoveWindow wnd x y w h repaint
foreign import ccall unsafe "windows.h MoveWindow"
  c_MoveWindow :: HWND -> Int -> Int -> Int -> Int -> Bool -> IO Bool

foreign import ccall unsafe "windows.h GetDesktopWindow"
  getDesktopWindow :: IO HWND

foreign import ccall unsafe "windows.h GetForegroundWindow"
  getForegroundWindow :: IO HWND

getParent :: HWND -> IO HWND
getParent wnd =
  failIfNull "GetParent" $ c_GetParent wnd
foreign import ccall unsafe "windows.h GetParent"
  c_GetParent :: HWND -> IO HWND

getTopWindow :: HWND -> IO HWND
getTopWindow wnd =
  failIfNull "GetTopWindow" $ c_GetTopWindow wnd
foreign import ccall unsafe "windows.h GetTopWindow"
  c_GetTopWindow :: HWND -> IO HWND


type SetWindowPosFlags = UINT

#{enum SetWindowPosFlags,
 , sWP_NOSIZE           = SWP_NOSIZE
 , sWP_NOMOVE           = SWP_NOMOVE
 , sWP_NOZORDER         = SWP_NOZORDER
 , sWP_NOREDRAW         = SWP_NOREDRAW
 , sWP_NOACTIVATE       = SWP_NOACTIVATE
 , sWP_FRAMECHANGED     = SWP_FRAMECHANGED
 , sWP_SHOWWINDOW       = SWP_SHOWWINDOW
 , sWP_HIDEWINDOW       = SWP_HIDEWINDOW
 , sWP_NOCOPYBITS       = SWP_NOCOPYBITS
 , sWP_NOOWNERZORDER    = SWP_NOOWNERZORDER
 , sWP_NOSENDCHANGING   = SWP_NOSENDCHANGING
 , sWP_DRAWFRAME        = SWP_DRAWFRAME
 , sWP_NOREPOSITION     = SWP_NOREPOSITION
 }

----------------------------------------------------------------
-- HDCs
----------------------------------------------------------------

type GetDCExFlags   = DWORD

#{enum GetDCExFlags,
 , dCX_WINDOW           = DCX_WINDOW
 , dCX_CACHE            = DCX_CACHE
 , dCX_CLIPCHILDREN     = DCX_CLIPCHILDREN
 , dCX_CLIPSIBLINGS     = DCX_CLIPSIBLINGS
 , dCX_PARENTCLIP       = DCX_PARENTCLIP
 , dCX_EXCLUDERGN       = DCX_EXCLUDERGN
 , dCX_INTERSECTRGN     = DCX_INTERSECTRGN
 , dCX_LOCKWINDOWUPDATE = DCX_LOCKWINDOWUPDATE
 }

-- apparently mostly fails if you use invalid hwnds

getDCEx :: HWND -> HRGN -> GetDCExFlags -> IO HDC
getDCEx wnd rgn flags =
  withForeignPtr rgn $ \ p_rgn ->
  failIfNull "GetDCEx" $ c_GetDCEx wnd p_rgn flags
foreign import ccall unsafe "windows.h GetDCEx"
  c_GetDCEx :: HWND -> PRGN -> GetDCExFlags -> IO HDC

getDC :: Maybe HWND -> IO HDC
getDC mb_wnd =
  failIfNull "GetDC" $ c_GetDC (maybePtr mb_wnd)
foreign import ccall unsafe "windows.h GetDC"
  c_GetDC :: HWND -> IO HDC

getWindowDC :: Maybe HWND -> IO HDC
getWindowDC mb_wnd =
  failIfNull "GetWindowDC" $ c_GetWindowDC (maybePtr mb_wnd)
foreign import ccall unsafe "windows.h GetWindowDC"
  c_GetWindowDC :: HWND -> IO HDC

releaseDC :: Maybe HWND -> HDC -> IO ()
releaseDC mb_wnd dc =
  failIfFalse_ "ReleaseDC" $ c_ReleaseDC (maybePtr mb_wnd) dc
foreign import ccall unsafe "windows.h ReleaseDC"
  c_ReleaseDC :: HWND -> HDC -> IO Bool

getDCOrgEx :: HDC -> IO POINT
getDCOrgEx dc =
  allocaPOINT $ \ p_pt -> do
  failIfFalse_ "GetDCOrgEx" $ c_GetDCOrgEx dc p_pt
  peekPOINT p_pt
foreign import ccall unsafe "windows.h GetDCOrgEx"
  c_GetDCOrgEx :: HDC -> Ptr POINT -> IO Bool

----------------------------------------------------------------
-- Caret
----------------------------------------------------------------

hideCaret :: HWND -> IO ()
hideCaret wnd =
  failIfFalse_ "HideCaret" $ c_HideCaret wnd
foreign import ccall unsafe "windows.h HideCaret"
  c_HideCaret :: HWND -> IO Bool

showCaret :: HWND -> IO ()
showCaret wnd =
  failIfFalse_ "ShowCaret" $ c_ShowCaret wnd
foreign import ccall unsafe "windows.h ShowCaret"
  c_ShowCaret :: HWND -> IO Bool

-- ToDo: allow arg2 to be NULL or {(HBITMAP)1}

createCaret :: HWND -> HBITMAP -> Maybe INT -> Maybe INT -> IO ()
createCaret wnd bm mb_w mb_h =
  failIfFalse_ "CreateCaret" $
    c_CreateCaret wnd bm (maybeNum mb_w) (maybeNum mb_h)
foreign import ccall unsafe "windows.h CreateCaret"
  c_CreateCaret :: HWND -> HBITMAP -> INT -> INT -> IO Bool

destroyCaret :: IO ()
destroyCaret =
  failIfFalse_ "DestroyCaret" $ c_DestroyCaret
foreign import ccall unsafe "windows.h DestroyCaret"
  c_DestroyCaret :: IO Bool

getCaretPos :: IO POINT
getCaretPos =
  allocaPOINT $ \ p_pt -> do
  failIfFalse_ "GetCaretPos" $ c_GetCaretPos p_pt
  peekPOINT p_pt
foreign import ccall unsafe "windows.h GetCaretPos"
  c_GetCaretPos :: Ptr POINT -> IO Bool

setCaretPos :: POINT -> IO ()
setCaretPos (x,y) =
  failIfFalse_ "SetCaretPos" $ c_SetCaretPos x y
foreign import ccall unsafe "windows.h SetCaretPos"
  c_SetCaretPos :: LONG -> LONG -> IO Bool

-- The remarks on SetCaretBlinkTime are either highly risible or very sad -
-- depending on whether you plan to use this function.

----------------------------------------------------------------
-- MSGs and event loops
--
-- Note that the following functions have to be reentrant:
--
--   DispatchMessage
--   SendMessage
--   UpdateWindow   (I think)
--   RedrawWindow   (I think)
--
-- The following dont have to be reentrant (according to documentation)
--
--   GetMessage
--   PeekMessage
--   TranslateMessage
--
-- For Hugs (and possibly NHC too?) this is no big deal.
-- For GHC, you have to use casm_GC instead of casm.
-- (It might be simpler to just put all this code in another
-- file and build it with the appropriate command line option...)
----------------------------------------------------------------

-- type MSG =
--   ( HWND   -- hwnd;
--   , UINT   -- message;
--   , WPARAM -- wParam;
--   , LPARAM -- lParam;
--   , DWORD  -- time;
--   , POINT  -- pt;
--   )

type LPMSG   = Addr

-- A NULL window requests messages for any window belonging to this thread.
-- a "success" value of 0 indicates that WM_QUIT was received

-- These guys return their data in static storage!?
getMessage_msg, getMessage2_msg, peekMessage_msg :: LPMSG
getMessage_msg  = unsafePerformIO (mallocBytes #{size MSG})
getMessage2_msg = unsafePerformIO (mallocBytes #{size MSG})
peekMessage_msg = unsafePerformIO (mallocBytes #{size MSG})

getMessage :: Maybe HWND -> IO LPMSG
getMessage mb_wnd = do
  failIf (== -1) "GetMessage" $
    c_GetMessage getMessage_msg (maybePtr mb_wnd) 0 0
  return getMessage_msg
foreign import ccall unsafe "windows.h GetMessageW"
  c_GetMessage :: LPMSG -> HWND -> UINT -> UINT -> IO Int

getMessage2 :: Maybe HWND -> IO (LPMSG, Bool)
getMessage2 mb_wnd = do
  res <- failIf (== -1) "GetMessage2" $
    c_GetMessage getMessage2_msg (maybePtr mb_wnd) 0 0
  return (getMessage2_msg, res /= 0)

-- A NULL window requests messages for any window belonging to this thread.
-- Arguably the code block shouldn't be a 'safe' one, but it shouldn't really
-- hurt.

peekMessage :: Maybe HWND -> UINT -> UINT -> UINT -> IO LPMSG
peekMessage mb_wnd filterMin filterMax remove = do
  failIf (== -1) "PeekMessage" $
    c_PeekMessage peekMessage_msg (maybePtr mb_wnd) filterMin filterMax remove
  return peekMessage_msg
foreign import ccall unsafe "windows.h PeekMessageW"
  c_PeekMessage :: LPMSG -> HWND -> UINT -> UINT -> UINT -> IO Int

-- Note: you're not supposed to call this if you're using accelerators

foreign import ccall unsafe "windows.h TranslateMessage"
  translateMessage :: LPMSG -> IO BOOL

updateWindow :: HWND -> IO ()
updateWindow wnd =
  failIfFalse_ "UpdateWindow" $ c_UpdateWindow wnd
foreign import ccall unsafe "windows.h UpdateWindow"
  c_UpdateWindow :: HWND -> IO Bool

-- Return value of DispatchMessage is usually ignored

foreign import ccall unsafe "windows.h DispatchMessageW"
  dispatchMessage :: LPMSG -> IO LONG

foreign import ccall unsafe "windows.h SendMessageW"
  sendMessage :: HWND -> WindowMessage -> WPARAM -> LPARAM -> IO LRESULT

----------------------------------------------------------------

-- ToDo: figure out reentrancy stuff
-- ToDo: catch error codes
--
-- ToDo: how to send HWND_BROADCAST to PostMessage
-- %fun PostMessage       :: MbHWND -> WindowMessage -> WPARAM -> LPARAM -> IO ()
-- %fun PostQuitMessage   :: Int -> IO ()
-- %fun PostThreadMessage :: DWORD -> WindowMessage -> WPARAM -> LPARAM -> IO ()
-- %fun InSendMessage     :: IO Bool

----------------------------------------------------------------
-- End
----------------------------------------------------------------