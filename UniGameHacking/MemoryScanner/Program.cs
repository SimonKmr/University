using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;

namespace MemoryScanner
{
    public class Program
    {
        static void Main(string[] args)
        {
            Scanner scanner = Scanner.Init("AssaultCube");
            var num = int.Parse(Console.ReadLine());
            var test = scanner.ScanProcess(num);
            Utility.Print(test);

            num = int.Parse(Console.ReadLine());
            var res = scanner.ValidateScan(test, num);
            Utility.Print(res);
        }
    }
}
