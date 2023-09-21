using System.Runtime.InteropServices;
using System;

namespace AssaultTrainer
{
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
}
