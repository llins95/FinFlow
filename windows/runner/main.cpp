#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  constexpr unsigned int kWindowWidth = 1280;
  constexpr unsigned int kWindowHeight = 800;
  const int screen_width = ::GetSystemMetrics(SM_CXSCREEN);
  const int screen_height = ::GetSystemMetrics(SM_CYSCREEN);
  const unsigned int origin_x =
      screen_width > static_cast<int>(kWindowWidth)
          ? static_cast<unsigned int>((screen_width - kWindowWidth) / 2)
          : 0;
  const unsigned int origin_y =
      screen_height > static_cast<int>(kWindowHeight)
          ? static_cast<unsigned int>((screen_height - kWindowHeight) / 2)
          : 0;

  Win32Window::Point origin(origin_x, origin_y);
  Win32Window::Size size(kWindowWidth, kWindowHeight);
  if (!window.Create(L"FinFlow", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
