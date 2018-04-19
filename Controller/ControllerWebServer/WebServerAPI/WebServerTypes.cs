using System;
using System.IO;
using System.Collections.Generic;
using System.Management.Instrumentation;
using System.Collections.ObjectModel;
using System.Threading;
using System.Diagnostics;

namespace Webserver
{
    public class WebPage
    {
        String HTMLCode;
        bool isReady = false;

        public void SetContent(String HTML)
        {
            HTMLCode = HTML;
            isReady = true;
        }

        public bool LoadContentFromFile(String HTMLFilePath)
        {
            if (!File.Exists(HTMLFilePath))
                return false;

            else
            {
                try
                {
                    SetContent(File.ReadAllText(HTMLFilePath));
                    isReady = true;
                    return true;
                }
                catch(Exception e)
                {
                    Console.WriteLine("There was an issue reading the HTML file. Exception thrown: " + e.InnerException);
                    return false;
                }
            }
        }
        public String FetchHTMLCode()
        {
            if (isReady)
                return HTMLCode;
            else
                return "";
        }
        public bool isValid()
        {
            if (isReady)
                return true;
            else
                return false;
        }
    }

    public class WebpageViewbagDefinitions
    {
        Dictionary<String, String> Definitions = new Dictionary<String, String>();

        bool isDefinitionRegistered(String DefinitionSymbol)
        {
            foreach(var symbol in Definitions)
            {
                if(symbol.Key == DefinitionSymbol)
                    return true;
            }

            return false;
        }

        public bool RegisterDefinition(String DefinitionSymbol, String DefinitionValue)
        {
            if (isDefinitionRegistered(DefinitionSymbol))
                return false;

            Definitions.Add(DefinitionSymbol, DefinitionValue);
            return true;
        }

        public Dictionary<String, String> GetDefinitions()
        {
            return Definitions;
        }
    }

    public static class ViewbagTranslator
    {
        public static String TranslateHTML(ref WebPage HTML, ref WebpageViewbagDefinitions Definitions)
        {
            if (!HTML.isValid())
                return "HTML object is invalid!";

            String HTMLRef = HTML.FetchHTMLCode();

            foreach (var def in Definitions.GetDefinitions())
            {
                HTMLRef = HTMLRef.Replace(def.Key, def.Value);
            }

            HTML.SetContent(HTMLRef);

            return HTMLRef;
        }

        public static String WebPrep(String HTML)
        {
            String HTMLRef = HTML;
            HTMLRef = HTMLRef.Replace("\n", "<br>");
            return HTMLRef;
        }
    }
}