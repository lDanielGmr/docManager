/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package clasesGenericas;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import ConexionBD.conexionBD;

public class loginValidacion {


    public static boolean validarUsuario(String usuario, String contrasenia) {
        boolean valido = false;
        String sql = "SELECT 1 FROM usuario WHERE usuario = ? AND `contraseña` = ?";

        try (Connection conn = conexionBD.conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, usuario);
            ps.setString(2, contrasenia);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    valido = true;
                }
            }

        } catch (Exception e) {
            System.err.println("Error al validar usuario:");
            e.printStackTrace();
        }

        return valido;
    }
}
