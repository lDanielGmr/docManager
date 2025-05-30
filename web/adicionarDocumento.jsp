<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.util.List,
    clasesGenericas.Usuario,
    clasesGenericas.Etiqueta
" %>
<%
    Usuario user = (Usuario) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    boolean plantillaMode = "true".equals(request.getParameter("plantilla"));

    List<Usuario> usuarios       = Usuario.findAll();
    List<Etiqueta> etiquetasList = Etiqueta.findAll();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title><%= plantillaMode ? "Subir nueva plantilla" : "Subir nuevo documento" %></title>
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
  </style>
</head>
<body>
  <div class="container">
    <h2>
      <i class="fas fa-upload"></i>
      <%= plantillaMode ? "Subir nueva plantilla" : "Subir nuevo documento" %>
    </h2>
    <p class="meta">
      Recibido por: <strong><%= user.getNombre() %></strong>
    </p>

    <form id="frmDoc"
          action="guardarDocumento.jsp"
          method="post"
          enctype="multipart/form-data">

      <input type="hidden" name="recibidoPor" value="<%= user.getId() %>"/>
      <input type="hidden" name="id_area"
             value='<%= user.getIdArea() != null ? user.getIdArea() : "" %>' />

      <div class="form-group">
        <label for="titulo">
          Título <span class="required">*</span>
        </label>
        <input type="text" id="titulo" name="titulo"
               required maxlength="255"
               placeholder="Ingrese un título"/>
      </div>

      <div class="form-group">
        <label for="tipo">Tipo</label>
        <input type="text" id="tipo" name="tipo"
               maxlength="100"
               placeholder="Tipo de documento"/>
      </div>

      <div class="form-group">
        <label>Área (su asignada)</label>
        <input type="text"
               value='<%= user.getArea() != null ? user.getArea() : "-" %>'
               disabled
               style="background:#f5f5f5;"/>
      </div>

      <div class="form-group inline">
        <input type="checkbox" id="esPlantilla"
               name="esPlantilla" value="true"
               <%= plantillaMode ? "checked disabled" : "" %> />
        <label for="esPlantilla">Es plantilla</label>
      </div>

      <div class="form-group inline">
        <input type="checkbox" id="requiereRespuesta"
               name="requiereRespuesta" value="true"
               <%= plantillaMode ? "disabled" : "" %> />
        <label for="requiereRespuesta"
               class="<%= plantillaMode ? "disabled-label" : "" %>">
          Requiere respuesta
        </label>
      </div>

      <div class="form-group">
        <label for="radicadoA">
          Radicado a <span class="required">*</span>
        </label>
        <select id="radicadoA" <%= plantillaMode ? "disabled" : "" %> >
          <option value="">-- Selecciona usuario --</option>
          <option value="NA">N/A</option>
          <% for (Usuario u : usuarios) {
               if (u.getId() == user.getId()) continue;
          %>
            <option value="<%= u.getId() %>">
              <%= u.getNombre() %>
            </option>
          <% } %>
        </select>
        <input type="hidden" id="radicadoHidden"
               name="radicadoA"
               value="<%= plantillaMode ? "NA" : "" %>" />
      </div>

      <div class="form-group">
        <label for="etqs">Etiquetas (Ctrl+clic)</label>
        <select id="etqs" multiple>
          <% for (Etiqueta et : etiquetasList) { %>
            <option value="<%= et.getId() %>">
              <%= et.getNombre() %>
            </option>
          <% } %>
        </select>
        <input type="hidden" name="etiquetas" id="etiquetas" />
      </div>

      <div class="form-group">
        <label for="file">
          Archivo <span class="required">*</span>
        </label>
        <input type="file" id="file" name="file"
               accept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.png"
               required />
      </div>

      <div class="buttons">
        <button type="button" class="btn-secondary"
                onclick="history.back()">
          <i class="fas fa-times"></i> Cancelar
        </button>
        <button type="submit" class="btn-primary">
          <i class="fas fa-save"></i> Guardar
        </button>
      </div>
    </form>
  </div>

  <div id="uploadOverlay">
    <div class="overlay-content">
      <p style="margin:0; font-size:1.1rem;">Guardando…</p>
      <progress id="uploadProgress" value="0" max="100"></progress>
    </div>
  </div>

  <script>
    const chkPlant = document.getElementById('esPlantilla'),
          selRad   = document.getElementById('radicadoA'),
          hidRad   = document.getElementById('radicadoHidden'),
          etqSelect= document.getElementById('etqs'),
          hidEtqs  = document.getElementById('etiquetas'),
          form     = document.getElementById('frmDoc'),
          overlay  = document.getElementById('uploadOverlay'),
          progress = document.getElementById('uploadProgress'),
          plantilla= <%= plantillaMode %>;

    if (plantilla) {
      selRad.value = 'NA';
      hidRad.value = 'NA';
      selRad.disabled = true;
    }
    chkPlant.addEventListener('change', () => {
      if (chkPlant.checked) {
        selRad.value = 'NA';
        hidRad.value = 'NA';
        selRad.disabled = true;
      } else {
        selRad.disabled = false;
        selRad.value = '';
        hidRad.value = '';
      }
    });
    if (!plantilla) {
      selRad.addEventListener('change', () => {
        hidRad.value = selRad.value;
      });
    }
    form.addEventListener('submit', function(e) {
      hidEtqs.value = Array.from(etqSelect.selectedOptions)
                          .map(o => o.value)
                          .join(',');
      if (chkPlant.checked) hidRad.value = 'NA';

      e.preventDefault();
      overlay.style.display = 'flex';
      const xhr = new XMLHttpRequest();
      xhr.open('POST', form.action, true);

      xhr.upload.addEventListener('progress', function(evt) {
        if (evt.lengthComputable) {
          const pct = Math.round((evt.loaded/evt.total)*100);
          progress.value = pct;
        }
      });

      xhr.addEventListener('loadend', function() {
        if (xhr.status === 200) {
          document.open();
          document.write(xhr.responseText);
          document.close();
        } else {
          alert('Error subiendo el archivo: ' + xhr.statusText);
          overlay.style.display = 'none';
        }
      });

      xhr.send(new FormData(form));
    });
  </script>
</body>
</html>
