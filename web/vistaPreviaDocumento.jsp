<%@ page language="java" contentType="text/html; charset=UTF-8"
         import="java.sql.*, ConexionBD.conexionBD" %>
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

    String titulo       = "", 
           tipo         = "", 
           area         = "", 
           nombreArchivo= "";
    Timestamp fecha     = null;

    try (Connection conn = conexionBD.conectar();
         PreparedStatement ps = conn.prepareStatement(
             "SELECT "
           + "  d.titulo, "
           + "  d.tipo, "
           + "  a.nombre   AS area, "
           + "  d.fecha_creacion, "
           + "  d.nombre_archivo "
           + "FROM documento d "
           + "LEFT JOIN area a ON d.id_area = a.id "
           + "WHERE d.id = ?"
         )) {

        ps.setInt(1, docId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                titulo        = rs.getString("titulo");
                tipo          = rs.getString("tipo");
                area          = rs.getString("area");            
                fecha         = rs.getTimestamp("fecha_creacion");
                nombreArchivo = rs.getString("nombre_archivo");
            } else {
                out.println("<p style='color:red;'>Documento no encontrado.</p>");
                return;
            }
        }
    } catch (Exception e) {
        out.println("<pre style='color:red;'>" + e.getMessage() + "</pre>");
        return;
    }

    String fileUrl = request.getContextPath() + "/uploads/" + nombreArchivo;
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Vista previa: <%= titulo %></title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <style>
    body { margin:0; font-family:Arial,sans-serif; }
    .header { padding:16px; background:#f5f5f5; border-bottom:1px solid #ddd; }
    .header h1 { margin:0; font-size:1.5rem; }
    .meta { padding:16px; display:flex; gap:24px; background:#fff; }
    .meta div { font-size:0.95rem; }
    .viewer { width:100%; height:calc(100vh - 144px); }
    .viewer embed { width:100%; height:100%; border:none; }
  </style>
</head>
<body>

  <div class="header">
    <h1><i class="fas fa-file-alt"></i> <%= titulo %></h1>
  </div>

  <div class="meta">
    <div><strong>Tipo:</strong> <%= tipo %></div>
    <div><strong>Área:</strong> <%= (area != null ? area : "—") %></div>
    <div><strong>Fecha:</strong> <%= fecha.toLocalDateTime().toLocalDate() %></div>
  </div>

  <div class="viewer">
    <embed src="<%= fileUrl %>" type="application/pdf">
    <p style="text-align:center; padding:16px;">
      Si no ves el documento,
      <a href="<%= fileUrl %>" target="_blank">haz clic aquí para descargarlo</a>.
    </p>
  </div>

</body>
</html>
