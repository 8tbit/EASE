using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.IO.Pipes;

namespace ModuleCore
{
    public class Alert
    {
        public String AlertId;
        public String AlertDescription;
    }

    public class Alerts
    {
        public String OwningModuleName;
        public List<Alert> RegisteredAlerts = new List<Alert>();

        public void Add(Alert AlertObj)
        {
            RegisteredAlerts.Add(AlertObj);
        }
    }

    public class AlertsContainer
    {
        public List<Alerts> AlertContainer = new List<Alerts>();
    }

    public enum ProcessStatus
    {
        Unaddressed,
        InProgress,
        Failed,
        Fixed
    }

    public class Process
    {
        public String OwningModule { get; set; }
        public String ProcessName { get; set; }
        public String ProcessDirections { get; set; }
        public ProcessStatus Status { get; set; }
        public DateTime RegisteredTime { get; set; }

        public String OutString()
        {
            return (OwningModule + "," + ProcessName + "," + ProcessDirections + "," + Status + "," + RegisteredTime);
        }
    }

    public static class Processes
    {

        public static List<Process> Procs = new List<Process> { };

        public static void LoadProcesses()
        {
            string Text = System.IO.File.ReadAllText(@".\SystemMemory\Processes.txt");
            System.Console.WriteLine(Text);
        }

        public static void RegisterProcess(Process Proc)
        {
            System.IO.File.AppendAllText(@".\SystemMemory\Processes.txt", Proc.OutString() + Environment.NewLine);
        }

        public static Process GetProcess(String ProcessName)
        {
            Process ProcessToSearch = new Process { ProcessName = ProcessName };

            foreach (var proc in Procs)
            {
                if (proc.ProcessName == ProcessToSearch.ProcessName)
                {
                    return proc;
                }
            }

            return ProcessToSearch;
        }
    }

    public static class ProcessController
    {
        private static int ConvertStringToProcessStatus(String ProcessString)
        {
            if (ProcessString == "Unaddressed") return 0;
            else if (ProcessString == "InProgress") return 1;
            else if (ProcessString == "Failed") return 2;
            else if (ProcessString == "Fixed") return 3;

            else return 0;
        }

        public static Process GetProcess(String ModuleName, String ProcName)
        {
            string Text = System.IO.File.ReadAllText(@".\SystemMemory\Processes.txt");
            string[] Processes = Text.Split('\n');

            foreach(var proc in Processes)
            {
                string[] Attribs = proc.Split(',');

                if (ModuleName == Attribs[0] && ProcName == Attribs[1])
                {

                    Process POut = new Process { OwningModule = Attribs[0], ProcessName = Attribs[1], ProcessDirections = Attribs[2], Status = (ProcessStatus) Enum.ToObject(typeof(ProcessStatus), ConvertStringToProcessStatus(Attribs[3])), RegisteredTime = Convert.ToDateTime(Attribs[4]) };
                    return POut;

                }
            }

            return new Process { };
        }

        public static void RemoveProcess(String ModuleName, String ProcName)
        {
            string line = null;
            string line_to_delete = GetProcess(ModuleName, ProcName).OutString();

            using (StreamReader reader = new StreamReader(@".\SystemMemory\Processes.txt"))
            {
                using (StreamWriter writer = new StreamWriter(@".\SystemMemory\Processes1.txt"))
                {
                    while ((line = reader.ReadLine()) != null)
                    {
                        if (String.Compare(line, line_to_delete) == 0)
                            continue;

                        writer.WriteLine(line);
                    }
                }
            }

            System.IO.File.Delete(@".\SystemMemory\Processes.txt");
            System.IO.File.Copy(@".\SystemMemory\Processes1.txt", @".\SystemMemory\Processes.txt");
            System.IO.File.Delete(@".\SystemMemory\Processes1.txt");
        }

        public static bool DoesProcessExist(String ModuleName, String ProcName)
        {
            if (GetProcess(ModuleName, ProcName).OwningModule != null)
            {
                return true;
            }

            else
                return false;
        }

        public static void AddProcess(String OwningModuleName, String ProcName, String Directions, ProcessStatus Status)
        {
            if(DoesProcessExist(OwningModuleName, ProcName))
            {
                return;
            }

            Process newProcess = new Process { ProcessName = ProcName, Status = Status, OwningModule = OwningModuleName, RegisteredTime = DateTime.Now, ProcessDirections = Directions };
            Processes.RegisterProcess(newProcess);
			
			return;
        }

        public static void AddProcess(Process Proc)
        {
            if(DoesProcessExist(Proc.OwningModule, Proc.ProcessName))
            {
                return;
            }

            Processes.RegisterProcess(Proc);
        }


        public static void UpdateProcessStatus(String OwningModuleName, String ProcName, ProcessStatus NewStatus)
        {
            if (!DoesProcessExist(OwningModuleName, ProcName))
                return;

            var proces = GetProcess(OwningModuleName, ProcName);
            RemoveProcess(OwningModuleName, ProcName);
            proces.Status = NewStatus;

            AddProcess(proces);
        }

    }

}
namespace ModuleStreamIO
{

}