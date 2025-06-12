<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.loginValidacion" %>
<%@ page import="javax.servlet.http.Cookie" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Inicio de Sesión</title>
    <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            background: url("images/login-bg.jpg") no-repeat center center fixed;
            background-size: cover;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .login-container {
            background: rgba(255, 255, 255, 0.9);
            padding: 40px;
            border-radius: 1px;
            box-shadow: 0 8px 16px rgba(0,0,0,0.3);
            width: 100%;
            max-width: 350px;
        }

        .login-box {
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        .header {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
        }

        .logo {
            height: 40px;
            margin-right: 10px;
        }

        .header-text {
            font-size: 20px;
            font-weight: bold;
            color: #333;
        }

        h1 {
            margin-bottom: 20px;
            color: #444;
        }

        .input-group {
            display: flex;
            align-items: center;
            margin-bottom: 15px;
            width: 100%;
            border: 1px solid #ccc;
            border-radius: 8px;
            padding: 10px;
            background-color: #fff;
        }

        .input-group i {
            margin-right: 10px;
            color: #888;
        }

        .input-group input {
            border: none;
            outline: none;
            flex: 1;
            font-size: 16px;
        }

        .remember-group {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
            width: 100%;
        }

        .remember-group input[type="checkbox"] {
            margin-right: 10px;
        }

        .btn-login {
            width: 100%;
            padding: 12px;
            font-size: 16px;
            background-color: #007BFF;
            color: #fff;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }

        .btn-login:hover {
            background-color: #0056b3;
        }

        .message.error {
            color: red;
            margin-top: 10px;
            font-weight: bold;
        }
    </style>
    <link rel="stylesheet" href="css/fontawesome.css" />
</head>
<body>
<%
    String u       = request.getParameter("username");
    String p       = request.getParameter("password");
    String remember = request.getParameter("remember");
    boolean loginError = false;

    if (u != null && p != null) {
        if (loginValidacion.validarUsuario(u, p)) {
            session.setAttribute("user", u);

            if ("on".equals(remember)) {
                Cookie userCookie = new Cookie("rememberedUser", u);
                Cookie passCookie = new Cookie("rememberedPass", p);
                userCookie.setMaxAge(60 * 60 * 24 * 7);  
                passCookie.setMaxAge(60 * 60 * 24 * 7);
                response.addCookie(userCookie);
                response.addCookie(passCookie);
            } else {
                Cookie userCookie = new Cookie("rememberedUser", "");
                Cookie passCookie = new Cookie("rememberedPass", "");
                userCookie.setMaxAge(0);
                passCookie.setMaxAge(0);
                response.addCookie(userCookie);
                response.addCookie(passCookie);
            }

            response.sendRedirect("inicio.jsp");
            return;
        } else {
            loginError = true;
        }
    }

    String rememberedUser = "";
    String rememberedPass = "";
    Cookie[] cookies = request.getCookies();
    if (cookies != null) {
        for (Cookie c : cookies) {
            if ("rememberedUser".equals(c.getName())) {
                rememberedUser = c.getValue();
            } else if ("rememberedPass".equals(c.getName())) {
                rememberedPass = c.getValue();
            }
        }
    }
%>

<div class="login-container">
    <div class="login-box">

        <div class="header">
            <img src="images/mini-logo.png" alt="Logo" class="logo">
            <span class="header-text">Terminal de Pasto</span>
        </div>

        <h1>Iniciar sesión</h1>

        <form action="index.jsp" method="post">
            <div class="input-group">
                <i class="fas fa-user"></i>
                <input
                  type="text"
                  name="username"
                  placeholder="Usuario"
                  value="<%= rememberedUser %>"
                  required
                >
            </div>
            <div class="input-group">
                <i class="fas fa-lock"></i>
                <input
                  type="password"
                  name="password"
                  placeholder="Contraseña"
                  value="<%= rememberedPass %>"
                  required
                >
            </div>

            <div class="remember-group">
                <input
                  type="checkbox"
                  id="remember"
                  name="remember"
                  <%= (!rememberedUser.isEmpty() && !rememberedPass.isEmpty()) ? "checked" : "" %>
                >
                <label for="remember">Recuérdame</label>
            </div>

            <button type="submit" class="btn-login">Siguiente</button>
        </form>

        <% if (loginError) { %>
            <p class="message error">❌ Usuario o contraseña incorrectos.</p>
        <% } %>
    </div>
</div>

</body>
</html>
