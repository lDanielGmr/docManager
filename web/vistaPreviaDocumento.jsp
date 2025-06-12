<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.sql.Timestamp,
    java.net.URLEncoder,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    ConexionBD.conexionBD
" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null) {
        out.println("<p style='color:red;'>Falta parámetro id.</p>");
        return;
    }
    int docId;
    try {
        docId = Integer.parseInt(idParam);
    } catch (NumberFormatException e) {
        out.println("<p style='color:red;'>ID inválido.</p>");
        return;
    }

    String titulo        = "",
           tipo          = "",
           area          = "",
           nombreArchivo = "";
    Timestamp fecha = null;

    String sql =
        "SELECT " +
        "  d.titulo, " +
        "  d.tipo, " +
        "  a.nombre         AS area, " +
        "  d.fecha_creacion, " +
        "  d.nombre_archivo " +
        "FROM documento d " +
        "LEFT JOIN area a ON d.id_area = a.id " +
        "WHERE d.id = ?";

    try (Connection conn = conexionBD.conectar();
         PreparedStatement ps = conn.prepareStatement(sql)) {

        ps.setInt(1, docId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                titulo        = rs.getString("titulo");
                tipo          = rs.getString("tipo");
                area          = rs.getString("area");
                fecha         = rs.getTimestamp("fecha_creacion");
                nombreArchivo = rs.getString("nombre_archivo");
                if (nombreArchivo == null || nombreArchivo.trim().isEmpty()) {
                    out.println("<p style='color:red;'>No se encontró el archivo asociado.</p>");
                    return;
                }
            } else {
                out.println("<p style='color:red;'>Documento no encontrado.</p>");
                return;
            }
        }
    } catch (Exception e) {
        out.println("<pre style='color:red;'>" + e.getMessage() + "</pre>");
        return;
    }

    String encodedName = URLEncoder.encode(nombreArchivo, "UTF-8").replace("+", "%20");
    String baseUrl = request.getScheme() + "://"
                   + request.getServerName()
                   + ":" + request.getServerPort()
                   + request.getContextPath();
    String fileUrl = baseUrl + "/uploads/" + encodedName;

    String gdocsUrl = "https://docs.google.com/gview?url="
                     + URLEncoder.encode(fileUrl, "UTF-8")
                     + "&embedded=true";
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Vista previa de: <%= titulo %></title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root {
      --accent: #007bff;
    }
    body { margin:0; font-family:Arial, sans-serif; }
    .header { padding:16px; background:#f5f5f5; border-bottom:1px solid #ddd; }
    .header h1 { margin:0; font-size:1.5rem; color:#333; }
    .meta { padding:16px; display:flex; gap:24px; background:#fff; }
    .meta div { font-size:0.95rem; color:#555; }
    .viewer { width:100%; height:calc(100vh - 144px); background:#eee; }
    .viewer iframe,
    .viewer object,
    .viewer img {
      width:100%; height:100%; border:none;
    }
    .fallback { text-align:center; padding:16px; }
    .fallback a { color: var(--accent); text-decoration:none; font-weight:bold; }
  </style>
</head>
<body>

  <div class="header">
    <h1><i class="fas fa-file-alt"></i> <%= titulo %></h1>
  </div>

  <div class="meta">
    <div><strong>Tipo:</strong> <%= (tipo != null && !tipo.isEmpty() ? tipo : "—") %></div>
    <div><strong>Área:</strong> <%= (area != null && !area.isEmpty() ? area : "—") %></div>
    <div><strong>Fecha:</strong> <%= fecha.toLocalDateTime().toLocalDate() %></div>
  </div>

  <div class="viewer">
    <%
      String lower = nombreArchivo.toLowerCase();
      if (lower.endsWith(".pdf")) {
    %>
      <iframe src="<%= fileUrl %>" type="application/pdf"></iframe>
      <div class="fallback">
        Si no ves el PDF, prueba en Google Docs:
        <a href="<%= gdocsUrl %>" target="_blank">Abrir con Google Docs Viewer</a><br>
        O descárgalo aquí:
        <a href="<%= fileUrl %>" target="_blank">Descargar PDF</a>.
      </div>
    <%
      } else if (lower.matches(".*\\.(doc|docx|xls|xlsx|ppt|pptx)$")) {
    %>
      <iframe src="<%= gdocsUrl %>"></iframe>
      <div class="fallback">
        Si no ves el documento, 
        <a href="<%= fileUrl %>" target="_blank">descárgalo aquí</a>.
      </div>
    <%
      } else if (lower.matches(".*\\.(jpg|jpeg|png|gif)$")) {
    %>
      <img src="<%= fileUrl %>" alt="Imagen">
      <div class="fallback">
        Si no ves la imagen,
        <a href="<%= fileUrl %>" target="_blank">descárgala aquí</a>.
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
