<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.util.List,
    java.util.Set,
    java.util.stream.Collectors,
    clasesGenericas.Documento,
    clasesGenericas.Etiqueta,
    clasesGenericas.Usuario
" %>
<%
    Usuario user = (Usuario) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    String idStr = request.getParameter("id");
    if (idStr == null) {
        out.println("<p style='color:red;'>Falta el parámetro id</p>");
        return;
    }
    int docId = Integer.parseInt(idStr);

    Documento doc;
    try {
        doc = Documento.findById(docId);
    } catch (Exception e) {
        throw new RuntimeException(e);
    }
    if (doc == null) {
        out.println("<p style='color:red;'>Documento no encontrado</p>");
        return;
    }

    List<Usuario> usuarios     = Usuario.findAll();
    List<Etiqueta> etiquetasAll = Etiqueta.findAll();
    Set<Integer> etiquetasAsignadas = doc.getEtiquetaIds().stream().collect(Collectors.toSet());
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Editar Documento</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
  <style>
    :root {
      --accent: #9d7aed;
      --text: #333;
      --light: #fff;
      --radius: 6px;
      --font: 'Poppins', sans-serif;
    }
    *, *::before, *::after { box-sizing: border-box; }
    body {
      font-family: var(--font);
      color: var(--text);
      margin: 0; padding: 20px;
      background: url('${pageContext.request.contextPath}/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
    }
    .container {
      max-width: 600px; margin: auto;
      background: var(--light);
      padding: 24px; border-radius: var(--radius);
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
    h2 { margin-top: 0; color: #333; }
    .meta { margin-bottom: 20px; font-weight: bold; }
    .form-group { margin-bottom: 16px; }
    label { display: block; margin-bottom: 4px; font-weight: 500; }
    input[type=text], select, input[type=file] {
      width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;
      font-size: .95rem;
    }
    .inline { display: flex; align-items: center; }
    .inline label { margin-left: 8px; font-weight: normal; }
    .required { color: red; }
    .buttons { text-align: right; margin-top: 24px; }
    .btn-primary {
      background: var(--accent); color: var(--light);
      padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer;
    }
    .btn-secondary {
      background: #ccc; color: #333;
      padding: 8px 16px; border: none; border-radius: 4px;
      margin-right: 8px; cursor: pointer;
    }
    .disabled-label { color: #999; }

    #uploadOverlay {
      display: none;
      position: fixed;
      top: 0; left: 0;
      width: 100%; height: 100%;
      background: rgba(0,0,0,0.5);
      align-items: center;
      justify-content: center;
      z-index: 9999;
    }
    #uploadOverlay .overlay-content {
      background: #fff;
      padding: 1.5rem;
      border-radius: 0.5rem;
      text-align: center;
      box-shadow: 0 0 0.5rem rgba(0,0,0,0.3);
      width: 300px;
    }
    #uploadOverlay progress {
      width: 100%;
      margin-top: 1rem;
    }
    :root {
      --accent: #9d7aed;
      --text: #333;
      --light: #fff;
      --radius: 6px;
      --font: 'Poppins', sans-serif;
    }
    *, *::before, *::after { box-sizing: border-box; }
    body {
      font-family: var(--font);
      color: var(--text);
      margin: 0; padding: 20px;
      background: url('${pageContext.request.contextPath}/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
    }
    .editor-container {
      max-width: 600px; margin: auto;
      background: var(--light);
      padding: 24px; border-radius: var(--radius);
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
    h2 { margin-top: 0; color: #333; }
    .form-group { margin-bottom: 16px; }
    label { display: block; margin-bottom: 4px; font-weight: 500; }
    input[type="text"], select, input[type="file"] {
      width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;
      font-size: .95rem;
    }
    .inline { display: flex; align-items: center; gap: 8px; }
    .btn { padding: 8px 16px; border: none; border-radius: 4px;
           cursor: pointer; font-size: .95rem; }
    .btn-primary { background: var(--accent); color: var(--light); }
    .btn-secondary { background: #ccc; color: #333; }
    .file-current { margin-left: 8px; font-style: italic; }
  </style>
</head>
<body>
  <div class="editor-container">
    <h2><i class="fas fa-edit"></i> Editar Documento</h2>

    <form action="guardarDocumento.jsp" method="post" enctype="multipart/form-data">
      <input type="hidden" name="id" value="<%=doc.getId()%>"/>

      <div class="form-group inline">
        <label>Archivo actual:</label>
        <span class="file-current"><%=doc.getNombreArchivo()%></span>
      </div>
      <div class="form-group inline">
        <label for="nuevoArchivo">Archivo nuevo:</label>
        <input type="file" id="nuevoArchivo" name="nuevoArchivo"/>
      </div>

      <div class="form-group">
        <label for="titulo">Título:</label>
        <input type="text" id="titulo" name="titulo" required
               value="<%=doc.getTitulo()%>"/>
      </div>

      <div class="form-group">
        <label>Tipo:</label>
        <div class="inline">
          <input type="radio" id="tipoInforme" name="tipo" value="Informe"
                 <%= "Informe".equals(doc.getTipo()) ? "checked" : "" %>/>
          <label for="tipoInforme">Informe</label>
          <input type="radio" id="tipoActa" name="tipo" value="Acta"
                 <%= "Acta".equals(doc.getTipo()) ? "checked" : "" %>/>
          <label for="tipoActa">Acta</label>
        </div>
      </div>

      <div class="form-group">
        <label for="area">Área:</label>
        <input type="text" id="area" name="area"
               value="<%=doc.getAreaNombre()%>" disabled/>
      </div>

      <div class="form-group inline">
        <label for="etqs">Etiquetas:</label>
        <select id="etqs" name="etiquetas" multiple size="4">
          <% for (Etiqueta et : etiquetasAll) { %>
            <option value="<%=et.getId()%>"
              <%= etiquetasAsignadas.contains(et.getId()) ? "selected" : "" %>>
              <%=et.getNombre()%>
            </option>
          <% } %>
        </select>
        <button type="button" class="btn btn-secondary"
                onclick="añadirEtiqueta()">Añadir etiqueta</button>
      </div>

      <div class="form-group">
        <label for="recibidoPor">Recibido por:</label>
        <select id="recibidoPor" name="recibidoPor" required>
          <% for (Usuario u : usuarios) { %>
            <option value="<%=u.getId()%>"
              <%= (doc.getRecibidoPor()!=null && u.getId()==doc.getRecibidoPor())
                  ? "selected" : "" %>>
              <%=u.getNombre()%>
            </option>
          <% } %>
        </select>
      </div>

      <div class="form-group">
        <label for="radicadoA">Radicado a:</label>
        <select id="radicadoA" name="radicadoA" required>
          <% for (Usuario u : usuarios) { %>
            <option value="<%=u.getId()%>"
              <%= (doc.getRadicadoA()!=null && u.getId()==doc.getRadicadoA())
                  ? "selected" : "" %>>
              <%=u.getNombre()%>
            </option>
          <% } %>
        </select>
      </div>

      <div class="form-group inline">
        <button type="submit" class="btn btn-primary">
          <i class="fas fa-save"></i> Guardar
        </button>
        <button type="button" class="btn btn-secondary"
                onclick="history.back()">
          <i class="fas fa-times"></i> Cancelar
        </button>
      </div>
    </form>
  </div>

  <script>
    async function añadirEtiqueta() {
      const nombre = prompt('Nombre de la nueva etiqueta:');
      if (!nombre) return;
      try {
        const resp = await fetch('crearEtiqueta.jsp?nombre=' + encodeURIComponent(nombre));
        if (!resp.ok) throw new Error(await resp.text());
        const json = await resp.json();
        const sel = document.getElementById('etqs');
        const opt = document.createElement('option');
        opt.value = json.id;
        opt.textContent = json.nombre;
        opt.selected = true;
        sel.appendChild(opt);
      } catch (err) {
        alert('Error al crear etiqueta: ' + err.message);
      }
    }
  </script>
</body>
</html>
