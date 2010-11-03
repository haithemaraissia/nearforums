<%@ Control Language="C#" Inherits="NearForums.Web.UI.BaseViewUserControl" %>
<%
	if (this.User.Group >= UserGroup.Moderator)
	{
%>
		<script type="text/javascript">
			var editorOptions = {
				script_url : "/scripts/tinymce/tiny_mce.js",
				theme : "advanced",
				theme_advanced_toolbar_location : "top",
				theme_advanced_toolbar_align : "left",
				theme_advanced_statusbar_location : "bottom",
				theme_advanced_resizing : true,
				content_css : "/styles/site.css",
				template_external_list_url : "lists/template_list.js",
				external_link_list_url : "lists/link_list.js",
				external_image_list_url : "lists/image_list.js",
				media_external_list_url : "lists/media_list.js",
				theme_advanced_buttons1 : "save,newdocument,|,bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontselect,fontsizeselect",
				theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,cleanup,help,|,forecolor,backcolor",
				theme_advanced_buttons3 : "code,|,charmap",
				width: "640",
				height: "220"
			};
		</script>
<%	
	}
	else
	{
%>
		<script type="text/javascript">
			var editorOptions = {
				script_url : "/scripts/tinymce/tiny_mce.js",
				theme : "advanced",
				theme_advanced_toolbar_location : "top",
				theme_advanced_toolbar_align : "left",
				theme_advanced_statusbar_location : "bottom",
				theme_advanced_resizing : true,
				content_css : "/styles/site.css",
				template_external_list_url : "lists/template_list.js",
				external_link_list_url : "lists/link_list.js",
				external_image_list_url : "lists/image_list.js",
				media_external_list_url : "lists/media_list.js",
				theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,bullist,numlist,|,undo,redo,|,link,unlink,anchor,image,help",
				theme_advanced_buttons2 : "",
				theme_advanced_buttons3 : "",
				theme_advanced_buttons4 : "",
				width: "640",
				height: "220"
			};
		</script>
<%
	}
%>

<script type="text/javascript" src="/scripts/tinymce/jquery.tinymce.js"></script>
<script type="text/javascript">
	$(document).ready(function() {
		$('#<%=ViewData["Name"] %>').tinymce(editorOptions);
	});
</script>