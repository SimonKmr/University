using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace MemoryScanner
{
    public class Scanner
    {
        //https://pinvoke.net/index.aspx

        [DllImport("user32.dll")]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll", SetLastError = true)]
        static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(uint processAccess, bool bInheritHandle, uint processId);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool ReadProcessMemory(IntPtr hProcess, int lpBase, [Out] byte[] lpBuffer, int nSize, out long lpNumberOfBytesRead);

        [DllImport("kernel32.dll")]
        static extern int VirtualQueryEx(IntPtr hProcess, IntPtr lpAddress, out MEMORY_BASIC_INFORMATION lpBuffer, uint dwLength);

        [StructLayout(LayoutKind.Sequential)]
        public struct MEMORY_BASIC_INFORMATION
        {
            public IntPtr BaseAddress;
            public IntPtr AllocationBase;
            public uint AllocationProtect;
            public IntPtr RegionSize;
            public uint State;
            public uint Protect;
            public uint Type;
        }

        public IntPtr hWnd { get; private set; }
        public uint pid { get; private set; }
        public IntPtr pHndl { get; private set; }
        public MEMORY_BASIC_INFORMATION[] Mbis { get; private set; }

        public static Scanner Init(string name)
        {
            return new Scanner(name);
        }

        public Scanner(string name)
        {
            uint tpid;
            hWnd = FindWindow(null, name);
            GetWindowThreadProcessId(hWnd, out tpid);
            pid = tpid;
            pHndl = OpenProcess(0x001F0FFF, false, (uint)pid);
            Mbis = GetMemoryBasicInformation(pHndl);

        }

        static MEMORY_BASIC_INFORMATION[] GetMemoryBasicInformation(IntPtr processHandle)
        {
            long address = 0;
            long MaxAddress = 0x7FFF0000;
            List<MEMORY_BASIC_INFORMATION> result = new List<MEMORY_BASIC_INFORMATION>();
            do
            {
                MEMORY_BASIC_INFORMATION m;
                VirtualQueryEx(processHandle, (IntPtr)address, out m, (uint)Marshal.SizeOf(typeof(MEMORY_BASIC_INFORMATION)));
                if (address == (long)m.BaseAddress + (long)m.RegionSize) break;
                address = (long)m.BaseAddress + (long)m.RegionSize;
                // 0x00000004 == Read + Write && 0x1000 = MEM_COMMIT
                if (m.Protect != 0x00000004 && m.State != 0x1000) continue;
                result.Add(m);
            } while (address <= MaxAddress);
            return result.ToArray();
        }

        public Hashtable ScanRegion(MEMORY_BASIC_INFORMATION m, int target)
        {
            var result = new Hashtable();
            long i = 0;
            do
            {
                long bytesread;
                byte[] buffer = new byte[(int)m.RegionSize];
                ReadProcessMemory(pHndl, (int)m.BaseAddress, buffer, (int)m.RegionSize, out bytesread);
                if (bytesread == 0) break;
                int[] integerValues = ReadBuffer(buffer);
                for (int x = 0; x < integerValues.Length; x++)
                    if (target == integerValues[x] && !result.ContainsKey((int)m.BaseAddress + x))
                        result.Add((int)m.BaseAddress + x, integerValues[x]);
                i += bytesread;
            } while (i < (long)m.RegionSize);
            return result;
        }

        public int ScanAddress(long address)
        {
            byte[] buffer = new byte[4];
            long bytesRead = 0;
            ReadProcessMemory(pHndl, (int)address, buffer, 4, out bytesRead);
            var res = ReadBuffer(buffer)[0];
            return res;
        }

        public Hashtable ScanProcess(int target)
        {
            List<Hashtable> scanTables = new List<Hashtable>();
            Hashtable result = new Hashtable();
            for (int i = 0; i < Mbis.Length; i++) scanTables.Add(ScanRegion(Mbis[i], target));
            for (int i = 0; i < scanTables.Count; i++)
                foreach(var t in scanTables[i].Keys)
                    if(!result.ContainsKey(t))
                        result.Add(t, scanTables[i][t]);
            return result;
        }

        public Hashtable ValidateScan(Hashtable previous, long target)
        {
            Hashtable result = new Hashtable();
            foreach (var p in previous.Keys)
            {
                var val = ScanAddress((int)p);
                if (val == target)
                    result.Add(p, val);
            }

            return result;
        }

        static int[] ReadBuffer(byte[] buffer)
        {
            List<int> result = new List<int>();
            for (int i = 0; i < buffer.Length-3; i ++)
                result.Add(BitConverter.ToInt32(buffer, i));
            return result.ToArray();
        }


    }
}
