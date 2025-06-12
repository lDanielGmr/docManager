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
    boolean esPlant = doc.isEsPlantilla();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Editar Documento</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root {
      --accent: #007bff;
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
    input[type="checkbox"] { margin-right: 8px; }
    .inline { display: flex; align-items: center; gap: 8px; }
    .btn { padding: 8px 16px; border: none; border-radius: 4px;
           cursor: pointer; font-size: .95rem; }
    .btn-primary { background: var(--accent); color: var(--light); }
    .btn-secondary { background: #ccc; color: #333; }
    .file-current { margin-left: 8px; font-style: italic; }
    .disabled-label { color: #999; }
  </style>
</head>
<body>
  <div class="editor-container">
    <h2><i class="fas fa-edit"></i> Editar Documento</h2>

    <form action="guardarDocumento.jsp" method="post" enctype="multipart/form-data">
      <input type="hidden" name="id" value="<%=doc.getId()%>"/>

s      <div class="form-group inline">
        <label>Archivo actual:</label>
        <span class="file-current"><%=doc.getNombreArchivo()%></span>
      </div>
      <div class="form-group inline">
        <label for="file">Archivo nuevo:</label>
        <input type="file" id="file" name="file"/>
      </div>

      <div class="form-group">
        <label for="titulo">Título:</label>
        <input type="text" id="titulo" name="titulo" required
               value="<%=doc.getTitulo()%>"/>
      </div>

      <div class="form-group">
        <label for="tipo">Tipo:</label>
        <input type="text" id="tipo" name="tipo"
               value="<%=doc.getTipo()%>" placeholder="Escriba el tipo…"/>
      </div>

      <div class="form-group">
        <label for="area">Área:</label>
        <input type="text" id="area" name="area"
               value="<%= user.getArea() != null ? user.getArea() : "-" %>" disabled/>
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

      <div class="form-group inline">
        <input type="checkbox" id="esPlantilla" name="esPlantilla"
               <%= esPlant ? "checked" : "" %> />
        <label for="esPlantilla">Es plantilla</label>
      </div>

      <div class="form-group">
        <label>Recibido por:</label>
        <input type="text" value="<%=user.getNombre()%>" disabled />
        <input type="hidden" name="recibidoPor" value="<%=user.getId()%>"/>
      </div>

      <div class="form-group">
        <label id="labelRadicadoA">Radicado a:</label>
        <input type="text"
               id="radicadoAText"
               value="No aplica"
               disabled
               class="disabled-label"
               style="<%= esPlant ? "" : "display:none;" %>" />

        <select id="radicadoASelect"
                name="radicadoA"
                <%= esPlant ? "style=\"display:none;\"" : "" %>
                required>
          <option value="">-- Seleccione --</option>
          <% for (Usuario u : usuarios) { %>
            <option value="<%=u.getId()%>"
              <%= (!esPlant && doc.getRadicadoA() != null && u.getId() == doc.getRadicadoA())
                  ? "selected" : "" %>>
              <%=u.getNombre()%>
            </option>
          <% } %>
        </select>
      </div>

      <div class="form-group inline">
        <button type="submit" id="submitBtn" class="btn btn-primary">
          <i class="fas fa-save"></i>
          <%= esPlant ? "Guardar" : "Enviar" %>
        </button>
        <button type="button" class="btn btn-secondary"
                onclick="history.back()">
          <i class="fas fa-times"></i> Cancelar
        </button>
      </div>
    </form>
  </div>

  <script>
    const chkPlant    = document.getElementById('esPlantilla');
    const selRadicado = document.getElementById('radicadoASelect');
    const txtRadicado = document.getElementById('radicadoAText');
    const lblRadicado = document.getElementById('labelRadicadoA');
    const btnSubmit   = document.getElementById('submitBtn');

    function ajustarInterfaz() {
      if (chkPlant.checked) {
        selRadicado.style.display = 'none';
        txtRadicado.style.display = '';
        selRadicado.disabled = true;
        lblRadicado.innerText = 'Radicado a: No aplica';
        btnSubmit.innerHTML = '<i class="fas fa-save"></i> Guardar';
      } else {
        txtRadicado.style.display = 'none';
        selRadicado.style.display = '';
        selRadicado.disabled = false;
        lblRadicado.innerText = 'Radicado a:';
        btnSubmit.innerHTML = '<i class="fas fa-paper-plane"></i> Enviar';
      }
    }

    chkPlant.addEventListener('change', ajustarInterfaz);
    ajustarInterfaz();

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
