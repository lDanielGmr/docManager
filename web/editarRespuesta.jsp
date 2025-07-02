<%@page import="org.apache.commons.fileupload.servlet.ServletFileUpload"%>
<%@ page language="java"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="
         java.io.File,
         java.io.InputStream,
         java.io.FileOutputStream,
         java.sql.Connection,
         java.sql.PreparedStatement,
         java.sql.ResultSet,
         java.sql.Timestamp,
         java.time.LocalDateTime,
         java.util.List,
         org.apache.commons.fileupload.FileItem,
         org.apache.commons.fileupload.disk.DiskFileItemFactory,
         org.apache.commons.fileupload.servlet.ServletFileUpload,
         ConexionBD.conexionBD
         "
         %>
<%
    request.setCharacterEncoding("UTF-8");
    String msgOK = null, msgErr = null;
    int respId = -1;
    String currentPath = "";
    Timestamp fechaSubida = null;

    String idParam = request.getParameter("id");
    if (idParam != null) {
        try {
            respId = Integer.parseInt(idParam);
            try (Connection cn = conexionBD.conectar(); PreparedStatement ps = cn.prepareStatement(
                    "SELECT archivo_path, fecha_subida FROM documento_respuesta WHERE id = ?"
            )) {
                ps.setInt(1, respId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        currentPath = rs.getString("archivo_path");
                        fechaSubida = rs.getTimestamp("fecha_subida");
                    } else {
                        out.println("<p class='err'>Respuesta no encontrada.</p>");
                        return;
                    }
                }
            }
        } catch (Exception e) {
            out.println("<p class='err'>Error leyendo datos iniciales: " + e.getMessage() + "</p>");
            return;
        }
    } else {
        out.println("<p class='err'>Falta parámetro <strong>id</strong>.</p>");
        return;
    }

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        boolean isMultipart = ServletFileUpload.isMultipartContent(request);
        if (!isMultipart) {
            msgErr = "El formulario no es multipart/form-data.";
        } else {
            try {
                DiskFileItemFactory factory = new DiskFileItemFactory();
                factory.setSizeThreshold(1024 * 1024);
                File tmpDir = new File(System.getProperty("java.io.tmpdir"));
                factory.setRepository(tmpDir);

                ServletFileUpload upload = new ServletFileUpload(factory);
                upload.setFileSizeMax(50 * 1024 * 1024);
                upload.setSizeMax(100 * 1024 * 1024);

                List<FileItem> parts = upload.parseRequest(request);
                FileItem fileItem = null;
                for (FileItem item : parts) {
                    if (!item.isFormField() && "archivo".equals(item.getFieldName())) {
                        fileItem = item;
                        break;
                    }
                }

                if (fileItem == null || fileItem.getName().trim().isEmpty()) {
                    msgErr = "No se recibió ningún archivo.";
                } else if (fileItem.getSize() == 0) {
                    msgErr = "El archivo está vacío.";
                } else {
                    String submitted = new File(fileItem.getName()).getName()
                            .replaceAll("\\s+", "_");
                    String fileName = System.currentTimeMillis() + "_" + submitted;

                    String uploadsDir = application.getRealPath("/uploads");
                    if (uploadsDir == null) {
                        uploadsDir = System.getProperty("java.io.tmpdir") + File.separator + "uploads";
                    }
                    File uploads = new File(uploadsDir);
                    if (!uploads.exists()) {
                        uploads.mkdirs();
                    }

                    File dest = new File(uploads, fileName);
                    try (InputStream in = fileItem.getInputStream(); FileOutputStream outF = new FileOutputStream(dest)) {
                        byte[] buffer = new byte[8192];
                        int len;
                        while ((len = in.read(buffer)) > 0) {
                            outF.write(buffer, 0, len);
                        }
                    }

                    String dbPath = "/uploads/" + fileName;
                    try (Connection cn = conexionBD.conectar(); PreparedStatement ps = cn.prepareStatement(
                            "UPDATE documento_respuesta SET archivo_path = ?, fecha_subida = ? WHERE id = ?"
                    )) {
                        ps.setString(1, dbPath);
                        ps.setTimestamp(2, Timestamp.valueOf(LocalDateTime.now()));
                        ps.setInt(3, respId);
                        int rows = ps.executeUpdate();
                        if (rows > 0) {
                            msgOK = "Respuesta actualizada correctamente.";
                            currentPath = dbPath;
                            fechaSubida = Timestamp.valueOf(LocalDateTime.now());
                        } else {
                            msgErr = "No se encontró la respuesta.";
                        }
                    }
                }
            } catch (Exception e) {
                msgErr = "Error al procesar archivo: " + e.getMessage();
                e.printStackTrace(new java.io.PrintWriter(out));
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <title>Editar Respuesta #<%= respId%></title>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/fontawesome.css">
        <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

        <style>
            html, body {
                height: 100%;
                margin: 0;
            }
            body {
                font-family: Arial, sans-serif;
                padding: 20px;
                background: url('<%=request.getContextPath()%>/images/login-bg.jpg') no-repeat center center fixed;
                background-size: cover;
            }
            form {
                max-width: 520px;
                margin: auto;
                background: rgba(255,255,255,0.9);
                padding: 20px;
                border-radius: 4px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.2);
            }
            .err {
                color: red;
                margin-bottom: 12px;
            }
            .ok {
                color: green;
                margin-bottom: 12px;
            }
            .current {
                margin-bottom: 16px;
            }
            a.file-link {
                text-decoration: none;
                color: #007bff;
            }
            a.file-link:hover {
                text-decoration: underline;
            }
            button {
                display: inline-flex;
                align-items: center;
                gap: 6px;
                background: #007bff;
                color: #fff;
                border: none;
                padding: 8px 16px;
                font-size: 1rem;
                border-radius: 4px;
                cursor: pointer;
            }
            button i {
                font-size: 1.2rem;
            }
            input[type="file"] {
                width: 100%;
                padding: 6px;
                border: 1px solid #ccc;
                border-radius: 4px;
                background: #fff;
            }
        </style>
    </head>
    <body>
        <h1 style="text-align:center;"><i class="fas fa-edit"></i> Editar Respuesta #<%= respId%></h1>
        <% if (msgOK != null) {%>
        <p class="ok"><%= msgOK%></p>
        <% } else if (msgErr != null) {%>
        <p class="err"><%= msgErr%></p>
        <% }%>

        <form method="post" enctype="multipart/form-data">
            <div class="current">
                <label>Archivo actual:</label><br>
                <a class="file-link" href="<%= request.getContextPath() + currentPath%>" target="_blank">
                    <i class="fas fa-file"></i>
                    <%= currentPath.substring(currentPath.lastIndexOf('/') + 1)%>
                </a><br>
                <small>Subido: <%= fechaSubida != null 
                                    ? fechaSubida.toLocalDateTime().toLocalDate() 
                                    : "" %></small>
            </div>
            <label>Selecciona nuevo archivo:</label>
            <input type="file" name="archivo" required>
            <br><br>
            <button type="submit"><i class="fas fa-save"></i> Guardar cambios</button>
        </form>
    </body>
</html>
