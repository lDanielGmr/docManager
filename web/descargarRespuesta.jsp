<%@ page language="java"
         contentType="application/octet-stream"
         pageEncoding="UTF-8"
%>
<%@ page import="
    java.io.File,
    java.io.FileInputStream,
    java.io.IOException,
    javax.servlet.ServletOutputStream,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.SQLException,
    ConexionBD.conexionBD
" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null || idParam.trim().isEmpty()) {
        response.setContentType("text/html; charset=UTF-8");
        out.println("<h3 style='color:red;'>Parámetro 'id' faltante.</h3>");
        return;
    }
    int respId;
    try {
        respId = Integer.parseInt(idParam);
    } catch (NumberFormatException ex) {
        response.setContentType("text/html; charset=UTF-8");
        out.println("<h3 style='color:red;'>ID de respuesta inválido.</h3>");
        return;
    }

    String archivoPath = null;
    try (Connection cn = conexionBD.conectar();
         PreparedStatement ps = cn.prepareStatement(
             "SELECT archivo_path FROM documento_respuesta WHERE id = ?"
         )) {
        ps.setInt(1, respId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                archivoPath = rs.getString("archivo_path");
            } else {
                response.setContentType("text/html; charset=UTF-8");
                out.println("<h3 style='color:red;'>Respuesta no encontrada (id=" + respId + ").</h3>");
                return;
            }
        }
    } catch (SQLException ex) {
        response.setContentType("text/html; charset=UTF-8");
        out.println("<h3 style='color:red;'>Error BD: " + ex.getMessage() + "</h3>");
        return;
    }

    String real = application.getRealPath(archivoPath);
    File file = (real != null)
                ? new File(real)
                : new File(System.getProperty("java.io.tmpdir") + File.separator + archivoPath);
    if (!file.exists() || !file.isFile()) {
        response.setContentType("text/html; charset=UTF-8");
        out.println("<h3 style='color:red;'>Archivo no encontrado en servidor.</h3>");
        return;
    }

    String fileName = file.getName();
    String mime = application.getMimeType(fileName);
    if (mime == null) mime = "application/octet-stream";

    response.reset();  
    response.setContentType(mime);
    response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
    response.setContentLengthLong(file.length());

    try (FileInputStream fis = new FileInputStream(file);
         ServletOutputStream sos = response.getOutputStream()) {

        byte[] buffer = new byte[16 * 1024];
        int bytesRead;
        while ((bytesRead = fis.read(buffer)) != -1) {
            sos.write(buffer, 0, bytesRead);
        }
        sos.flush();
    } catch (IOException ioe) {
        log("Error enviando archivo para id=" + respId, ioe);
    }
%>
