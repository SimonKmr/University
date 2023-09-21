using System;
using System.IO;

namespace AssaultTrainer
{
    internal class Program
    {
        static void Main(string[] args)
        {
            Console.Clear();
            Console.WriteLine();
            Console.WriteLine("################################");
            Console.WriteLine("##### AC Game-Trainer v1.0 #####");
            Console.WriteLine("################################");
            Console.WriteLine();
            var hwnd = Win32.FindWindow(null,"AssaultCube");
            uint processId = 0;
            var res = Win32.GetWindowThreadProcessId(hwnd, out processId);
            var handleProcess = Win32.OpenProcess(0x0400 ^ 0x0008 ^ 0x0010 ^ 0x0020, true, processId);

            Trainer trainer = new Trainer(handleProcess);

            while (true)
            {
                var key = (Keys) HotKeyManager.WaitForKey();

                if (key == Keys.NumPad1)
                {
                    Console.WriteLine("Health +100");
                    trainer.AddHealth();
                }
                if (key == Keys.NumPad2)
                {
                    Console.WriteLine("Ammo +20");
                    trainer.AddAmmo();
                }
                if (key == Keys.NumPad3)
                {
                    Console.WriteLine("Enabled: NoRecoil");
                    trainer.NoRecoil();
                }
                if (key == Keys.NumPad4)
                {

                }
                if (key == Keys.NumPad5)
                {
                    Console.WriteLine("Enabled: NoRifeAnimations");
                    trainer.DisableRifleAnimations();
                }
            }
        }
    }
}