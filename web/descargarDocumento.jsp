<%@ page contentType="application/octet-stream" pageEncoding="UTF-8" language="java" %>
<%@ page import="
    java.io.File,
    java.io.FileInputStream,
    java.io.IOException,
    java.io.OutputStream,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.SQLException
" %>
<%@ page import="ConexionBD.conexionBD" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null || idParam.trim().isEmpty()) {
        response.setContentType("text/html; charset=UTF-8");
        out.println("<h3 style='color:red;'>Parámetro 'id' faltante.</h3>");
        return;
    }

    int docId;
    try {
        docId = Integer.parseInt(idParam);
    } catch (NumberFormatException e) {
        response.setContentType("text/html; charset=UTF-8");
        out.println("<h3 style='color:red;'>ID de documento inválido.</h3>");
        return;
    }

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    String nombreArchivo = null;

    try {
        conn = conexionBD.conectar();
        String sql = "SELECT nombre_archivo FROM documento WHERE id = ? AND eliminado = 0";
        ps = conn.prepareStatement(sql);
        ps.setInt(1, docId);
        rs = ps.executeQuery();
        if (rs.next()) {
            nombreArchivo = rs.getString("nombre_archivo");
        } else {
            response.setContentType("text/html; charset=UTF-8");
            out.println("<h3 style='color:red;'>Documento no encontrado o eliminado.</h3>");
            return;
        }
    } catch (SQLException ex) {
        response.setContentType("text/html; charset=UTF-8");
        out.println("<h3 style='color:red;'>Error al consultar la base de datos: " 
                    + ex.getMessage() + "</h3>");
        return;
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException ignore) {}
        try { if (ps != null) ps.close(); } catch (SQLException ignore) {}
        try { if (conn != null) conn.close(); } catch (SQLException ignore) {}
    }

    String uploadsDirPath = application.getRealPath("/") + File.separator + "uploads";
    File archivo = new File(uploadsDirPath, nombreArchivo);
    if (!archivo.exists() || !archivo.isFile()) {
        response.setContentType("text/html; charset=UTF-8");
        out.println("<h3 style='color:red;'>El archivo físico no existe en el servidor.</h3>");
        return;
    }

    String mimeType = application.getMimeType(archivo.getName());
    if (mimeType == null) {
        mimeType = "application/octet-stream";
    }

    FileInputStream fis = null;
    try {
        response.reset();
        response.setContentType(mimeType);
        response.setContentLengthLong(archivo.length());
        String headerValue = String.format("attachment; filename=\"%s\"", archivo.getName());
        response.setHeader("Content-Disposition", headerValue);

        fis = new FileInputStream(archivo);
        OutputStream os = response.getOutputStream();
        byte[] buffer = new byte[4096];
        int bytesRead;
        while ((bytesRead = fis.read(buffer)) != -1) {
            os.write(buffer, 0, bytesRead);
        }
        os.flush();
    } catch (IOException ioe) {
        response.setContentType("text/html; charset=UTF-8");
        out.println("<h3 style='color:red;'>Error al enviar el archivo: " + ioe.getMessage() + "</h3>");
    } finally {
        try { if (fis != null) fis.close(); } catch (IOException ignore) {}
    }
%>
