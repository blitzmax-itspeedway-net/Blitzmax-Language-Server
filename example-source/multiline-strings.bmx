SuperStrict
 
Framework brl.standardio
Import text.markdown
 
Local sb:TStringBuilder = New TStringBuilder
 
TMarkdown.ParseToHtml("""
Hello *World*!
* First
* Second
""", sb)
 
Print sb.ToString()
