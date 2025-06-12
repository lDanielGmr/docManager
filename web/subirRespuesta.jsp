<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         import="
           java.io.File,
           java.nio.file.Paths,
           java.sql.Connection,
           java.sql.PreparedStatement,
           java.sql.SQLException,
           java.time.Instant,
           java.util.List,
           javax.servlet.ServletContext,
           javax.servlet.http.HttpSession,
           clasesGenericas.Usuario,
           ConexionBD.conexionBD,
           org.apache.commons.fileupload.FileItem,
           org.apache.commons.fileupload.disk.DiskFileItemFactory,
           org.apache.commons.fileupload.servlet.ServletFileUpload
         " %>
<%
    request.setCharacterEncoding("UTF-8");

    HttpSession ses = request.getSession(false);
    Usuario usuario = (ses != null) 
                    ? (Usuario) ses.getAttribute("user")
                    : null;
    if (usuario == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    String docIdParam = request.getParameter("documentoId");
    if (docIdParam == null) {
        docIdParam = request.getParameter("id");
    }
    int documentoId;
    try {
        documentoId = Integer.parseInt(docIdParam);
    } catch (Exception e) {
        out.println("<p style='color:red;'>ID de documento inválido.</p>");
        return;
    }

    String mensaje     = null;
    String tipoMensaje = null; 

    boolean isMultipart = ServletFileUpload.isMultipartContent(request);

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        if (!isMultipart) {
            tipoMensaje = "error";
            mensaje     = "El formulario no es multipart.";
        } else {
            try {
                DiskFileItemFactory factory = new DiskFileItemFactory();
                factory.setSizeThreshold(1024 * 1024); 
                ServletContext ctx = getServletContext();
                File tmpDir = (File) ctx.getAttribute("javax.servlet.context.tempdir");
                factory.setRepository(tmpDir);

                ServletFileUpload upload = new ServletFileUpload(factory);
                upload.setFileSizeMax(5 * 1024 * 1024);
                upload.setSizeMax(10 * 1024 * 1024);   

                @SuppressWarnings("unchecked")
                List<FileItem> items = upload.parseRequest(request);

                FileItem archivoItem = null;
                for (FileItem item : items) {
                    if (!item.isFormField() && "archivoRespuesta".equals(item.getFieldName())) {
                        archivoItem = item;
                        break;
                    }
                }

                if (archivoItem == null || archivoItem.getName().isEmpty()) {
                    tipoMensaje = "error";
                    mensaje     = "Debes seleccionar un archivo.";
                } else {
                    String webRoot    = ctx.getRealPath("/");
                    String folderPath = webRoot + File.separator + "respuestas";
                    File carpeta      = new File(folderPath);
                    if (!carpeta.exists()) carpeta.mkdirs();

                    String original = Paths.get(archivoItem.getName()).getFileName().toString();
                    String unico    = Instant.now().toEpochMilli() + "_" + original;
                    File destino    = new File(carpeta, unico);
                    archivoItem.write(destino);

                    String dbPath = "respuestas/" + unico;
                    try (Connection conn = conexionBD.conectar();
                         PreparedStatement ps = conn.prepareStatement(
                           "INSERT INTO documento_respuesta "
                         + "(documento_id, archivo_path, uploaded_by) VALUES (?,?,?)")) {

                        ps.setInt   (1, documentoId);
                        ps.setString(2, dbPath);
                        ps.setInt   (3, usuario.getId());
                        ps.executeUpdate();
                    }

                    tipoMensaje = "success";
                    mensaje     = "Se ha adjuntado el archivo correctamente.";
                }
            } catch (Exception ex) {
                tipoMensaje = "error";
                mensaje     = "Error subiendo archivo: " + ex.getMessage();
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Adjuntar Respuesta</title>
  <link rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"
        crossorigin="anonymous" />
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    body { margin:0; padding:20px; font-family:'Poppins',sans-serif; background:#f4f4f4; }
    .container { max-width:600px; margin:0 auto; background:#fff; padding:20px;
                 border-radius:6px; box-shadow:0 2px 8px rgba(0,0,0,0.1); }
    h1 { margin:0 0 1rem; font-size:1.5rem; }
    table { width:100%; border-collapse:collapse; }
    th, td { padding:8px; border:1px solid #ccc; background:#fff; color:#000; }
    th { text-align:left; }
    input[type=file] {
      display:block; width:100%; padding:6px; border:1px solid #ccc;
      border-radius:4px; background:#fff; color:#000;
    }
    button {
      display:inline-flex; align-items:center; gap:6px;
      background:#007bff; color:#fff; border:none;
      padding:8px 16px; font-size:1rem; border-radius:4px; cursor:pointer;
    }
    button i { font-size:1.2rem; }
    .message {
      margin-top:1rem; padding:10px; background:#fff; color:#000;
      border:1px solid #ccc; border-radius:4px;
    }
    .message.error { border-color:#e74c3c; color:#e74c3c; }
    .message.success { border-color:#2ecc71; color:#2ecc71; }
  </style>
</head>
<body>
  <div class="container">
    <h1><i class="fa-solid fa-paperclip"></i> Adjuntar Respuesta</h1>
    <% if (mensaje != null) { %>
      <div class="message <%= tipoMensaje %>"><%= mensaje %></div>
    <% } %>
    <form method="post"
          enctype="multipart/form-data"
          action="subirRespuesta.jsp?documentoId=<%= documentoId %>">
      <input type="hidden" name="documentoId" value="<%= documentoId %>">
      <table>
        <tr>
          <th>Selecciona archivo</th>
          <td><input type="file" name="archivoRespuesta"></td>
        </tr>
      </table>
      <br>
      <button type="submit">
        <i class="fa-solid fa-paper-plane"></i> Subir Respuesta
      </button>
    </form>
  </div>
</body>
</html>
