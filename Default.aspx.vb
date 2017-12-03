Imports System.Data
Imports System.Data.SqlClient

Partial Class demos_auto_hashtag_Default
    Inherits System.Web.UI.Page

	Sub btnSubmit_click(ByVal Sender As Object, ByVal E As EventArgs) Handles btnSubmit.Click
		'get terms from database
		Dim arrTerms As New ArrayList()
		arrTerms = GetAllTerms()

		'get unique words from input text
		Dim arrWords As New ArrayList()
		arrWords = ExtractTerms(tbInput.Text)

		If arrTerms.Count < 1 Then
			lblResult.Text = "There are no terms in the database, or there was an error retrieving the terms."
			lblResult.CssClass = "warning"
		ElseIf arrWords.Count < 1 Then
			lblResult.Text = "There are no words in the string to be tagged."
			lblResult.CssClass = "warning"
		Else
			'get matches between terms and input words
			Dim arrHashes As New ArrayList()
			arrHashes = CompareLists(arrTerms, arrWords)

			If arrHashes.Count < 1 Then
				lblResult.Text = "There were no matches between the input text and the terms in the database."
				lblResult.CssClass = ""
			Else
				'display found terms
				Dim sbMsg As New StringBuilder("The following terms were found: ")
				For Each strTerm As String In arrHashes
					sbMsg.Append(strTerm)
					sbMsg.Append(", ")
				Next
				sbMsg.Remove(sbMsg.Length - 2, 2)
				lblResult.Text = sbMsg.ToString()
				lblResult.CssClass = ""   
				
				'autotag input string
				tbInput.Text = AutoTagSubject(tbInput.Text, arrHashes)
			End If
		End If

	End Sub

	Function GetAllTerms() As ArrayList
		'retrieves all terms from the database
		'returns empty ArrayList on error,
		'populated ArrayList on success

		Dim arrOut As New ArrayList()

		Dim objConn As New SqlConnection(ConfigurationManager.ConnectionStrings("connMain").ConnectionString)
		Dim objCmd As New SqlCommand("sp_auto_hashtag_terms_get_all", objConn)
		objCmd.CommandType = CommandType.StoredProcedure

		Dim objReader As SqlDataReader
		objConn.Open()
		objReader = objCmd.ExecuteReader()
		While objReader.Read()
			arrOut.Add(objReader(0))
		End While
		objConn.Close()
		objCmd.Dispose()
		objConn.Dispose()

		Return arrOut
	End Function

	Function ExtractTerms(ByVal strInput As String) As ArrayList
		'extracts all words from textbox
		'returns them as ArrayList, empty ArrayList on error
		'words are any alphanumeric sequence proceeding a space or newline

		Dim arrOut As New ArrayList()

		Dim reWords As New Regex("\w+(\s|$)", RegexOptions.IgnoreCase Or RegexOptions.CultureInvariant)
		Dim reMatches As MatchCollection = reWords.Matches(tbInput.Text)

		For Each reMatch As Match In reMatches
			arrOut.Add(reMatch.Value.Trim)
		Next

		Return arrOut
	End Function

	Function CompareLists(ByVal arrTerms As ArrayList, ByVal arrWords As ArrayList) As ArrayList
		'compares term list against word list
		'returns ArrayList with all words found in terms
		'maintains case

		Dim arrOut As New ArrayList()

		For Each strWord As String In arrWords
			For Each strTerm As String In arrTerms
				If strTerm.ToLower = strWord.ToLower Then
					arrOut.Add(strWord)
					Exit For
				End If
			Next
		Next

		Return arrOut
	End Function

	Function AutoTagSubject(ByVal strInput As String, ByVal arrTerms As ArrayList) As String
		'applies arrTerms as hashtags to strInput
		'removes hashtags first to avoid double-tagging
		
		Dim strOut As String = strInput
		strOut = strOut.Replace("#", "")

		For Each strTerm As String In arrTerms
			strOut = strOut.Replace(strTerm, "#" & strTerm)
		Next

		Return strOut
	End Function

End Class
