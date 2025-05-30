/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package ConexionBD;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class conexionBD {

    private static final String URL = "jdbc:mysql://localhost:3306/gestion_documental";
    private static final String USER = "root"; 
    private static final String PASSWORD = "admin"; 

    public static Connection conectar() {
        Connection conn = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(URL, USER, PASSWORD);
            System.out.println("Conexión exitosa a la base de datos.");
        } catch (ClassNotFoundException e) {
            System.out.println("Error: Driver MySQL no encontrado.");
            e.printStackTrace();
        } catch (SQLException e) {
            System.out.println("Error de conexión a la base de datos.");
            e.printStackTrace();
        }
        return conn;
    }
}
