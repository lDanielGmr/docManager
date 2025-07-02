<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.io.File,
    java.io.FileInputStream,
    java.io.IOException,
    java.io.OutputStream,
    java.net.URLEncoder,
    java.sql.Timestamp,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    ConexionBD.conexionBD
" %>
<%
    String download = request.getParameter("download");
    if ("true".equalsIgnoreCase(download)) {
        String nombreArchivo = request.getParameter("file");
        if (nombreArchivo == null) {
            response.sendError(400, "Falta parámetro file");
            return;
        }
        String uploadsDirPath = System.getenv("UPLOADS_DIR");
        if (uploadsDirPath == null || uploadsDirPath.trim().isEmpty()) {
            String userHome = System.getProperty("user.home");
            uploadsDirPath = userHome + File.separator + "uploads_app";
            File d = new File(uploadsDirPath);
            if (!d.exists() && !d.mkdirs()) {
                uploadsDirPath = application.getRealPath("/") + File.separator + "uploads";
            }
        }
        File fichero = new File(uploadsDirPath, nombreArchivo);
        if (!fichero.exists()) {
            response.sendError(404, "Archivo no encontrado: " + nombreArchivo);
            return;
        }
        String lower = nombreArchivo.toLowerCase();
        String contentType = getServletContext().getMimeType(nombreArchivo);
        if (contentType == null) {
            if (lower.endsWith(".pdf")) contentType = "application/pdf";
            else if (lower.matches(".*\\.(jpg|jpeg)")) contentType = "image/jpeg";
            else if (lower.endsWith(".png")) contentType = "image/png";
            else contentType = "application/octet-stream";
        }
        response.setContentType(contentType);
        try (FileInputStream in = new FileInputStream(fichero);
             OutputStream fileOut = response.getOutputStream()) {
            byte[] buf = new byte[4096];
            int len;
            while ((len = in.read(buf)) > 0) {
                fileOut.write(buf, 0, len);
            }
        } catch (IOException e) {
        }
        return;
    }


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

    String titulo        = "", tipo = "", area = "", nombreArchivo = "";
    Timestamp fecha      = null;

    String sql =
        "SELECT d.titulo, d.tipo, a.nombre AS area, d.fecha_creacion, d.nombre_archivo " +
        "FROM documento d LEFT JOIN area a ON d.id_area = a.id WHERE d.id = ?";

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

    String baseUrl = request.getScheme() + "://"
                   + request.getServerName() + ":"
                   + request.getServerPort()
                   + request.getContextPath();
    String encodedName = URLEncoder.encode(nombreArchivo, "UTF-8").replace("+", "%20");
    String fileUrl = baseUrl
                   + request.getServletPath()
                   + "?download=true&file=" + encodedName;

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
    :root { --accent: #007bff; }
    body { margin:0; font-family:Arial, sans-serif; }
    .header { padding:16px; background:#f5f5f5; border-bottom:1px solid #ddd; }
    .header h1 { margin:0; font-size:1.5rem; color:#333; }
    .meta { padding:16px; display:flex; gap:24px; background:#fff; }
    .meta div { font-size:0.95rem; color:#555; }
    .viewer { width:100%; height:calc(100vh - 144px); background:#eee; }
    .viewer iframe, .viewer object, .viewer img {
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
    <div><strong>Tipo:</strong> <%= (tipo!=null&&!tipo.isEmpty()?tipo:"—") %></div>
    <div><strong>Área:</strong> <%= (area!=null&&!area.isEmpty()?area:"—") %></div>
    <div><strong>Fecha:</strong> <%= fecha.toLocalDateTime().toLocalDate() %></div>
  </div>
  <div class="viewer">
    <%
      String lowerExt = nombreArchivo.toLowerCase();
      if (lowerExt.endsWith(".pdf")) {
    %>
      <iframe src="<%= fileUrl %>" type="application/pdf"></iframe>
      <div class="fallback">
        Si no ves el PDF, prueba en Google Docs:
        <a href="<%= gdocsUrl %>" target="_blank">Abrir con Google Docs Viewer</a><br>
        O descárgalo aquí:
        <a href="<%= fileUrl %>" target="_blank">Descargar PDF</a>.
      </div>
    <%
      } else if (lowerExt.matches(".*\\.(doc|docx|xls|xlsx|ppt|pptx)$")) {
    %>
      <iframe src="<%= gdocsUrl %>"></iframe>
      <div class="fallback">
        Si no ves el documento,
        <a href="<%= fileUrl %>" target="_blank">descárgalo aquí</a>.
      </div>
    <%
      } else if (lowerExt.matches(".*\\.(jpg|jpeg|png|gif)$")) {
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
 