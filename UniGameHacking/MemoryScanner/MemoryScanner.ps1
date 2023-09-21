Clear
Write-Output ""
Write-Output "###############################"
Write-Output "##### Memory Scanner v0.1 #####"
Write-Output "###############################"
Write-Output ""

# Import Windows API functions


# TODO: Vervollst�ndigen der Imports mit den genutzten API-Funktionen.

Add-Type @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Collections;


    public class Scanner
    {
        //https://pinvoke.net/index.aspx

        [DllImport("user32.dll")]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll", SetLastError = true)]
        static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess( uint processAccess, bool bInheritHandle, uint processId);

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

        public Scanner(string name){
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

        public int ScanAddress(long address)
        {
            byte[] buffer = new byte[4];
            long bytesRead = 0;
            ReadProcessMemory(pHndl, (int)address, buffer, 4, out bytesRead);
            var res = ReadBuffer(buffer)[0];
            return res;
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

'@

# 1. Obtain process handle in the following order: WindowHandle -----> ProcessId -----> PID for OpenProcess

# TODO: Setzen Sie die folgenden globalen Variablen ($hwnd, $processid und $handle_process), indem Sie zun�chst das WindowHandle eines laufenden AssaultCube Prozesses bestimmen ($hwnd).
# Ermitteln Sie unter Verwendung des bestimmten WindowHandles die ProcessID des AssaultCube Prozesses ($processid).
# Erlangen Sie mittels der ProcessID (als Vorbereitung f�r den Speicherzugriff) ein Handle f�r den AssaultCube Prozess ($handle_process), Berechtigungen mindestens: PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE.





$wname='AssaultCube' # any existing window name
$scanner = [Scanner]::Init($wname);

# TODO
$hwnd = $scanner.hWnd
Write-Output("Window Handle: " + $hwnd)

# TODO
$processid = $scanner.pid
Write-Output("Process ID: " + $processid)

# TODO
$handle_process = $scanner.pHndl
Write-Output("Process Handle: " + $handle_process)



# 2. Initial scan - read memory and scan for 4-byte values:

# TODO: Implementieren Sie die folgende Funktion, die einen 4-Byte Scan-Wert $scan_value entgegennimmt und den Arbeitsspeicher des ermittelten AssaultCube Prozesses nach diesem Wert scannt (nur 4-Byte Werte!).
# Die Funktion soll eine Hashtable zur�ckgeben, welche als Keys die Adressen enth�lt, deren Wert mit $scan_value �bereinstimmt. Setzen Sie als zugeh�rige Value der Hashtable-Keys (Adressen) den ausgelesenen 4-Byte Wert der Adresse.
# Beachten Sie, dass aus Performancegr�nden lediglich Speicherbl�cke gescannt werden sollen, die den Status MEM_COMMIT und die Protection PAGE_READWRITE aufweisen.
# Starten Sie mit dem Scannen des Arbeitsspeichers an der Adresse 0.


function Scan-Memory {

    param (
        $scan_value
    )

    $memory_locations = @{}


    $memory_locations = $scanner.ScanProcess($scan_value)


    return $memory_locations

}



# 3. Re-scan the results of the initial scan in endless loop

# TODO: Implementieren Sie die folgende Funktion, die einen 4-Byte Scan-Wert $scan_value sowie eine Hashtable $memory_locations{Adresse:Wert} entgegennimmt.
# Die Funktion soll f�r jede der in $memory_locations enthaltenen Adressen (Hashtable-Keys) den aktuellen 4-Byte Wert im Arbeitsspeicher des bestimmten AssaultCube Prozesses auslesen. 
# Die Funktion soll ein Hashtable zur�ckgeben, welches als Keys die Adressen enth�lt, deren Wert mit $scan_value �bereinstimmen. Setzen Sie als zugeh�rige Value der Hashtable-Keys (Adressen) den ausgelesenen 4-Byte Wert der Adresse.


function Validate-Scan {

    param (
        $scan_value,
        $memory_locations
    )

   $validated_locations = $memory_locations.Clone()
   $validated_locations = $scanner.ValidateScan($memory_locations,$scan_value)


    return $validated_locations

}

Write-Output ""
Write-Output ""

$start_value = Read-Host -Prompt "Start scan with value ?"
$initial = Scan-Memory $start_value

#Write-Output $initial


while ($true) {

    $locations = $initial.Clone()

    #Write-Output $locations

    $value = [int](Read-Host -Prompt "Validate scan with value ?")

    $initial = Validate-Scan $value $locations

    Write-Output $initial 

}

