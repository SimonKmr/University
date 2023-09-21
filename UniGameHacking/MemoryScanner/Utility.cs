using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemoryScanner
{
    internal class Utility
    {
        public static void Print(Hashtable table)
        {
            foreach (var e in table.Keys)
            {
                Console.WriteLine(e + ";" + table[e]);
            }
        }

        public static Hashtable Intersect(Hashtable current, Hashtable previous)
        {
            Hashtable result = new Hashtable();
            foreach (var p in previous.Keys)
                if (current.ContainsKey(p))
                    result.Add(p, current[p]);
            return result;
        }
    }
}
