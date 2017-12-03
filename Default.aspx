<%@ Page Title="Automatically Hash Tagging Text With ASP.NET Web Forms (VB.NET)" Language="VB" MasterPageFile="~/Default.master" AutoEventWireup="false" CodeFile="Default.aspx.vb" Inherits="demos_auto_hashtag_Default"  UnobtrusiveValidationMode="None" %>

<asp:Content ID="cntSidebar" ContentPlaceHolderID="cphSidebar" runat="server"></asp:Content>
<asp:Content ID="cntMain" ContentPlaceHolderID="cphMain" runat="server">
    <!--
  
    Automatically Hash Tagging Text With ASP.NET Web Forms (VB.NET)
    Copyright (C) 2011 Doug Vanderweide
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    -->
    
	<h2>Automatically Hash Tagging Text With ASP.NET Web Forms (VB.NET)</h2>
	<p class="note">Demonstrates how to automatically tag an input string with terms contained in a database.</p>
	<p><asp:Label runat="server" ID="lblResult" Text='Enter some text in the box, then click the submit button. Results will be shown here.' /></p>
	<asp:TextBox runat="server" ID="tbInput" TextMode="MultiLine" Rows="10" Columns="50" Text="Amazon uses HTML5 and JavaScript; Google owns YouTube."  />
	<asp:RequiredFieldValidator runat="server" ID="rfvInput" ControlToValidate="tbInput" ErrorMessage='<br />Please provide some text.' CssClass="warning" Display="Dynamic" />
	<br />
	<asp:Button runat="server" ID="btnSubmit" Text="Submit" />

	<h4>Terms in the database</h4>
	<asp:DataList runat="server" ID="dlTerms" DataSourceID="sqlTerms" RepeatColumns="10" RepeatDirection="Horizontal" CellPadding="5" CellSpacing="0" ItemStyle-BorderColor="Black" ItemStyle-BorderWidth="1">
		<ItemTemplate>
			<%#Eval("term_text")%>
		</ItemTemplate>
	</asp:DataList>

	<asp:SqlDataSource runat="server" ID="sqlTerms" SelectCommand="sp_auto_hashtag_terms_get_all" SelectCommandType="StoredProcedure" ConnectionString="<%$ ConnectionStrings:connMain %>" />
	
	<h4>Form</h4>
	<pre class="brush: xml">
		&lt;h2&gt;Automatically Hash Tagging Text With ASP.NET Web Forms (VB.NET)&lt;/h2&gt;
		&lt;p&gt;&lt;asp:Label runat="server" ID="lblResult" Text='Enter some text in the box, then click the submit button. Results will be shown here.' /&gt;&lt;/p&gt;
		&lt;asp:TextBox runat="server" ID="tbInput" TextMode="MultiLine" Rows="10" Columns="50" Text="Amazon uses HTML5 and JavaScript; Google owns YouTube."  /&gt;
		&lt;asp:RequiredFieldValidator runat="server" ID="rfvInput" ControlToValidate="tbInput" ErrorMessage='&lt;br /&gt;Please provide some text.' CssClass="warning" Display="Dynamic" /&gt;
		&lt;br /&gt;
		&lt;asp:Button runat="server" ID="btnSubmit" Text="Submit" /&gt;

		&lt;h4&gt;Terms in the database&lt;/h4&gt;
		&lt;asp:DataList runat="server" ID="dlTerms" DataSourceID="sqlTerms" RepeatColumns="10" RepeatDirection="Horizontal" CellPadding="5" CellSpacing="0" ItemStyle-BorderColor="Black" ItemStyle-BorderWidth="1"&gt;
			&lt;ItemTemplate&gt;
				&lt;%#Eval("term_text")%&gt;
			&lt;/ItemTemplate&gt;
		&lt;/asp:DataList&gt;

		&lt;asp:SqlDataSource runat="server" ID="sqlTerms" SelectCommand="your stored procedure" SelectCommandType="StoredProcedure" ConnectionString="&lt;%$ ConnectionStrings:your connection string %&gt;" /&gt;
	</pre>
	
	<h4>Code Behind</h4>
	<pre class="brush: vb">
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

			Dim objConn As New SqlConnection(ConfigurationManager.ConnectionStrings("your connection string").ConnectionString)
			Dim objCmd As New SqlCommand("your stored procedure", objConn)
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

	</pre>
</asp:Content>
