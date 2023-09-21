Clear
Write-Output ""
Write-Output "################################"
Write-Output "##### AC Game-Trainer v1.0 #####"
Write-Output "################################"
Write-Output ""

# Prerequisites for native callback of SetWindowsHookEx in Powershell (delegate function necessary)
# Taken from https://www.reddit.com/r/PowerShell/comments/f5b1z2/ideas_for_using_powershell_as_a_hotkey_tool/
Add-Type -TypeDefinition '
using System;
using System.IO;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace HotKey {
  public static class Main {
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;

    private static HookProc hookProc = HookCallback;
    private static IntPtr hookId = IntPtr.Zero;
    private static int keyCode = 0;

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    public static int WaitForKey() {
      hookId = SetHook(hookProc);
      Application.Run();
      UnhookWindowsHookEx(hookId);
      return keyCode;
    }

    private static IntPtr SetHook(HookProc hookProc) {
      IntPtr moduleHandle = GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName);
      return SetWindowsHookEx(WH_KEYBOARD_LL, hookProc, moduleHandle, 0);
    }

    private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
      if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
        keyCode = Marshal.ReadInt32(lParam);
        Application.Exit();
      }
      return CallNextHookEx(hookId, nCode, wParam, lParam);
    }
  }
}
' -ReferencedAssemblies System.Windows.Forms

Add-Type @'
using System.Runtime.InteropServices;
using System;

    public class Trainer
    {
        //Importing WindowsApi
        [DllImport("kernel32.dll")]
        public static extern IntPtr OpenProcess(int access, bool inheritHandler, uint processId);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, [Out] byte[] lpBuffer, int dwSize, out IntPtr lpNumberOfBytesRead);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, Int32 nSize, out IntPtr lpNumberOfBytesWritten);

        //Real Code
        
        private IntPtr processHandle;

        public Trainer(IntPtr processHandle)
        {
            this.processHandle = processHandle;
        }

        public static Trainer Init(IntPtr processHandle)
        {
            return new Trainer(processHandle);
        }

        public void AddHealth()
        {
            //Get Current Location of Health Value
            IntPtr bytesWritten;
            var bufferSize = 4;
            var buffer = new byte[bufferSize];

            //Get Pointer Address
            ReadProcessMemory(processHandle, (IntPtr)0x58AC00, buffer, bufferSize, out bytesWritten);
            var healthAddress = BitConverter.ToUInt32(buffer,0) ;

            //Get Health Address
            ReadProcessMemory(processHandle, (IntPtr)healthAddress + 0xEC, buffer, bufferSize, out bytesWritten);
            var health = BitConverter.ToUInt32(buffer, 0);

            //Set Updated Value
            buffer = BitConverter.GetBytes(health + 100);
            WriteProcessMemory(processHandle, (IntPtr)healthAddress + 0xEC, buffer, bufferSize, out bytesWritten);
        }

        public void AddAmmo()
        {
            IntPtr bytesWritten;
            var bufferSize = 4;
            var buffer = new byte[bufferSize];

            ReadProcessMemory(processHandle, (IntPtr)0x58AC00, buffer, bufferSize, out bytesWritten);
            var ammoAddress = BitConverter.ToUInt32(buffer, 0);

            ReadProcessMemory(processHandle, (IntPtr)ammoAddress + 0x140, buffer, bufferSize, out bytesWritten);
            var ammo = BitConverter.ToUInt32(buffer, 0);

            buffer = BitConverter.GetBytes(ammo + 20);
            WriteProcessMemory(processHandle, (IntPtr)ammoAddress + 0x140, buffer, bufferSize, out bytesWritten);
        }

        public void NoRecoil()
        {
            //Override Code with NoOps
            IntPtr bytesWritten;
            var bufferSize = 5;
            var buffer = new byte[bufferSize];
            for (int i = 0; i < bufferSize; i++) buffer[i] = 0x90;
            WriteProcessMemory(processHandle, (IntPtr)0x004C2EC3, buffer, bufferSize, out bytesWritten);
        }

        public void DisableRifleAnimations()
        {
            IntPtr bytesWritten;
            var bufferSize = 3;
            var buffer = new byte[bufferSize];
            for (int i = 0; i < bufferSize; i++) buffer[i] = 0x90;
            WriteProcessMemory(processHandle, (IntPtr)0x004C73E7, buffer, bufferSize, out bytesWritten);
        }

        public void EnableRadar()
        {

        }
    }
'@

# 1. Obtain process handle in the following order: WindowHandle -----> ProcessId -----> PID for OpenProcess

# HWND myWindow = FindWindow(NULL, "Title of the game window here");
# GetWindowThreadProcessId(myWindow, &PID);

$hwnd = [Trainer]::FindWindow([NullString]::Value, "AssaultCube")
Write-Output("Window Handle: " + $hwnd)

$processid = 0
$res = [Trainer]::GetWindowThreadProcessId($hwnd, [ref] $processid)
Write-Output("Process ID: " + $processid)

# OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE, FALSE, $PID)
# PROCESS_ALL_ACCESS = 0x1fffff
$handle_process = [Trainer]::OpenProcess(0x0400 -bor 0x0008 -bor 0x0010 -bor 0x0020, $true, $processid)
Write-Output("Process Handle: " + $handle_process)

$trainer = [trainer]::Init($handle_process)

# 2. Game Trainer Logic
#  	- Numpad 1:  Add 100 Health Points (TODO !)
#  	- Numpad 2:  Add 100 Ammo Points (TODO !)
#  	- Numpad 3:  NoRecoil (Optional)
#  	- Numpad 4:  Radar Hack (Optional)


# TODO - Health Trainer
function Add-Health {
    $trainer.AddHealth()
}

    
# TODO - Ammo Trainer
function Add-Ammo {
    $trainer.AddAmmo()
}

function No-Recoil {
    $trainer.NoRecoil()
}


Write-Output ""
Write-Output ""
Write-Output "NumPad1: +100 Health"
Write-Output "NumPad2: +20 Ammo"
Write-Output "NumPad3: No Recoil (enable only)"
Write-Output ""
Write-Output ""


# Endless Loop
while ($true) {
    $key = [System.Windows.Forms.Keys][HotKey.Main]::WaitForKey()
    # NumPad1, NumPad2, ...
    if ($key -eq "NumPad1"){
	    Write-Host "Health +100"
	    Add-Health
    }

    if ($key -eq "NumPad2"){
	    Write-Host "Ammo +20"
	    Add-Ammo
    }

    if ($key -eq "NumPad3"){
	    Write-Host "No Rec"
	    No-Recoil
    }
}

