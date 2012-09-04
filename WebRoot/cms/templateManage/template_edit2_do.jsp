<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="com.frameworkset.platform.cms.templatemanager.*"%>
<%@ page import="com.frameworkset.platform.cms.container.*"%>
<%@ page import="com.frameworkset.platform.security.AccessControl"%>
<%@page import="com.frameworkset.platform.cms.driver.htmlconverter.*"%>
<%@page import="com.frameworkset.platform.cms.driver.i18n.*"%>
<%@page import="com.frameworkset.platform.util.RemoteFileHandle"%>
<%@ page import="com.frameworkset.platform.cms.sitemanager.*"%>
<%@page import="java.util.*"%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<title></title>
</head>
<body>
<%
try{
	AccessControl control = AccessControl.getInstance();
	control.checkAccess(request, response);
 	 
 	String userId = control.getUserID()+""; 
	Template tplt = new Template();
	//获取站点在文件系统中的绝对路径
	String siteId = request.getParameter("siteId");
	
	String uri = request.getParameter("uri");
	String fileName = request.getParameter("fileName");	
	
	//首先完成重命名的工作，200710261725，weida
	String oldFileName = request.getParameter("oldFileName");
	if(!fileName.equals(oldFileName)){
		FileManager fileManager = new FileManagerImpl();
		fileManager.reName(siteId, uri, userId, oldFileName, fileName);
	}
	
	tplt.setTemplatePath(uri);
	
	if(fileName!=null && fileName.trim().length()!=0){
		tplt.setTemplateFileName(fileName);
	}	
	String theURI = "";
	if("1".equals(request.getParameter("persistType"))){
		if(uri!=null&&uri.trim().length()!=0){
			if(!uri.endsWith("/")){
				theURI = uri+"/"; 
			}
		}
		if(fileName==null || fileName.trim().length()==0){
			throw new Exception("模板存储在文件系统中，但是没有提供主文件名！");
		}
		try{
			new FileManagerImpl().checkInFile(siteId,theURI+fileName,userId);
		}catch(Exception e){
			//如果没有check in 也不要影响正常的编辑
			e.printStackTrace();			
		}
	}

	SiteManager siteManager = new SiteManagerImpl();

	String sitedir = siteManager.getSiteInfo(siteId).getSiteDir();//站点相对路径
	
	if(siteId == null || siteId.trim().length()==0){
		throw new Exception("获取参数站点id失败,无法根据id去查找目录");
	}
	tplt.setSiteId(Integer.parseInt(siteId));

	String templateId = request.getParameter("templateId");
	
	if(templateId == null || templateId.trim().length()==0){
		throw new Exception("没有提供模板id,无法更新模板");
	}
	tplt.setTemplateId(Integer.parseInt(templateId));


	
	
	String content = ""+request.getParameter("content");
	//处理文档内容
	CmsLinkProcessor processor = new CmsLinkProcessor(request,uri,sitedir);
	processor.setHandletype(CmsLinkProcessor.PROCESS_EDITTEMPLATE);
	try {
		String tempcontent = processor.process(content,CmsEncoder.ENCODING_UTF_8);
		content = tempcontent;
		CmsLinkTable linktable = processor.getExternalPageLinkTable();
		Iterator it = linktable.iterator();
		while(it.hasNext())
		{
			CmsLinkProcessor.CMSLink link = (CmsLinkProcessor.CMSLink)it.next();
			String remoteAddr = link.getOrigineLink().getHref();
			String contentPath = link.getRelativeFilePath();
			String localPath = config.getServletContext().getRealPath("/") + "cms/siteResource/" + sitedir + "/_template/" + contentPath;
			System.out.println("1"+localPath);
			try {
				//远程信息本地化
				RemoteFileHandle rf = new RemoteFileHandle(remoteAddr,localPath);
				rf.download();
			} catch (Exception e) {
				System.out.println("取远程图片时出错！");
				e.printStackTrace();
			}
		}
	} catch (Exception e) {
		e.printStackTrace();
	}

	tplt.setText(content);
	
	String templateName = request.getParameter("templateName");
	if(templateName==null||templateName.trim().length()==0){
		throw new Exception("请提供模板名称!");
	}
	tplt.setName(templateName);
	
	String templateDesc = request.getParameter("templateDesc");
	if(templateDesc==null||templateDesc.trim().length()==0){
		throw new Exception("请提供模板简短描述!");
	}
	tplt.setDescription(templateDesc);
	
	String templateType = request.getParameter("templateType");
	tplt.setType(Integer.parseInt(templateType));
	
	tplt.setCreateUserId(Long.parseLong(control.getUserID()));
	
	tplt.setHeader("null");
	
	int persistType	= Integer.parseInt(request.getParameter("persistType"));
	
	tplt.setPersistType(persistType);
	
	int styleId = Integer.parseInt(request.getParameter("templateStyle"));
	tplt.setStyle(styleId);

	new TemplateManagerImpl().updateAllInfoOfTemplate(tplt);
	%>
	
	<script language="javascript">
		alert('编辑模板成功');
		var str = window.dialogArguments.location.href;
		var strArray = str.slice(0,str.indexOf("?"));
		window.dialogArguments.location.href = strArray+"?"+window.dialogArguments.document.all.queryString.value;
		top.close();
	</script>
<%}catch(Exception e){
	out.println("<script language=\"javascript\">");
	out.println("alert('"+e.toString().substring(e.toString().indexOf(":")+2)+"');");
	out.println("</script>");
	//e.printStackTrace();
}%>
</body>
</html>