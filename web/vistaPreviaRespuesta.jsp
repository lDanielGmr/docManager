<%@ page import="
    java.net.URLEncoder,
    java.io.PrintWriter,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.Timestamp,
    ConexionBD.conexionBD
" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null) {
        out.println("<p style='color:red;'>Falta parámetro id.</p>");
        return;
    }
    int respId;
    try {
        respId = Integer.parseInt(idParam);
    } catch (NumberFormatException e) {
        out.println("<p style='color:red;'>ID inválido.</p>");
        return;
    }

    String archivoPath = null;
    Timestamp fechaSubida = null;
    int docId = -1;
    String respSql =
      "SELECT documento_id, archivo_path, fecha_subida " +
      "FROM documento_respuesta WHERE id = ?";
    try (Connection conn = conexionBD.conectar();
         PreparedStatement ps = conn.prepareStatement(respSql)) {
        ps.setInt(1, respId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                docId       = rs.getInt("documento_id");
                archivoPath = rs.getString("archivo_path");
                fechaSubida = rs.getTimestamp("fecha_subida");
            } else {
                out.println("<p style='color:red;'>Respuesta no encontrada.</p>");
                return;
            }
        }
    } catch (Exception e) {
        out.println("<pre style='color:red;'>" + e.getMessage() + "</pre>");
        return;
    }

    String titulo = "", tipo = "", area = "";
    Timestamp fechaDoc = null;
    String docSql =
      "SELECT d.titulo, d.tipo, a.nombre AS area, d.fecha_creacion " +
      "FROM documento d " +
      "LEFT JOIN area a ON d.id_area = a.id " +
      "WHERE d.id = ?";
    try (Connection conn = conexionBD.conectar();
         PreparedStatement ps2 = conn.prepareStatement(docSql)) {
        ps2.setInt(1, docId);
        try (ResultSet rs2 = ps2.executeQuery()) {
            if (rs2.next()) {
                titulo   = rs2.getString("titulo");
                tipo     = rs2.getString("tipo");
                area     = rs2.getString("area");
                fechaDoc = rs2.getTimestamp("fecha_creacion");
            } else {
                out.println("<p style='color:red;'>Documento original no encontrado.</p>");
                return;
            }
        }
    } catch (Exception e) {
        out.println("<pre style='color:red;'>" + e.getMessage() + "</pre>");
        return;
    }

    if (archivoPath == null || archivoPath.trim().isEmpty()) {
        out.println("<p style='color:red;'>No se encontró el archivo de respuesta.</p>");
        return;
    }

    String ctx = request.getContextPath(); 
    String rel = archivoPath.startsWith("/") ? archivoPath.substring(1) : archivoPath;
    String fileUrl = ctx + "/" + rel;        
    String fullUrl = request.getScheme() + "://" +
                     request.getServerName() + ":" +
                     request.getServerPort() +
                     fileUrl;
    String gdocsUrl = "https://docs.google.com/gview?url=" +
                      URLEncoder.encode(fullUrl, "UTF-8") +
                      "&embedded=true";
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Previsualizar Respuesta: <%= titulo %></title>
  <link rel="stylesheet" href="<%=ctx%>/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root { --accent: #007bff; }
    body { margin:0; font-family:Arial,sans-serif; }
    .header { padding:16px; background:#f5f5f5; border-bottom:1px solid #ddd; }
    .header h1 { margin:0; font-size:1.5rem; color:#333; }
    .meta { padding:16px; display:flex; gap:24px; background:#fff; }
    .meta div { font-size:0.95rem; color:#555; }
    .viewer { width:100%; height:calc(100vh - 144px); background:#eee; }
    .viewer iframe, .viewer img { width:100%; height:100%; border:none; }
    .fallback { text-align:center; padding:16px; }
    .fallback a { color: var(--accent); text-decoration:none; font-weight:bold; }
  </style>
</head>
<body>

  <div class="header">
    <h1><i class="fas fa-reply"></i> <%= titulo %></h1>
  </div>

  <div class="meta">
    <div><strong>Tipo Doc:</strong> <%= (tipo!=null&&!tipo.isEmpty()?tipo:"—") %></div>
    <div><strong>Área:</strong>    <%= (area!=null&&!area.isEmpty()?area:"—") %></div>
    <div><strong>Doc Fecha:</strong> <%= fechaDoc.toLocalDateTime().toLocalDate() %></div>
    <div><strong>Subida:</strong>   <%= fechaSubida.toLocalDateTime().toLocalDate() %></div>
  </div>

  <div class="viewer">
    <%
      String lower = rel.toLowerCase();
      if (lower.endsWith(".pdf")) {
    %>
      <iframe src="<%= fileUrl %>" type="application/pdf"></iframe>
      <div class="fallback">
        Si no ves el PDF, usa
        <a href="<%= gdocsUrl %>" target="_blank">Google Docs Viewer</a><br>
        o <a href="<%= fileUrl %>" target="_blank">descárgalo</a>.
      </div>
    <%
      } else if (lower.matches(".*\\.(doc|docx|xls|xlsx|ppt|pptx)$")) {
    %>
      <iframe src="<%= gdocsUrl %>"></iframe>
      <div class="fallback">
        Si no ves el documento, <a href="<%= fileUrl %>" target="_blank">descárgalo aquí</a>.
      </div>
    <%
      } else if (lower.matches(".*\\.(jpg|jpeg|png|gif)$")) {
    %>
      <img src="<%= fileUrl %>" alt="Imagen de respuesta">
      <div class="fallback">
        Si no ves la imagen, <a href="<%= fileUrl %>" target="_blank">descárgala</a>.
      </div>
    <%
      } else {
    %>
      <div class="fallback">
        No se puede previsualizar este tipo de archivo.<br>
        <a href="<%= fileUrl %>" target="_blank">Descárgalo aquí</a>.
      </div>
    <%
      }
    %>
  </div>

</body>
</html>
