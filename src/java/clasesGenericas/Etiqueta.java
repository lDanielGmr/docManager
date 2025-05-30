package clasesGenericas;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import ConexionBD.conexionBD;

public class Etiqueta {
    private int id;
    private String nombre;

    public Etiqueta() { }

    public Etiqueta(int id, String nombre) {
        this.id = id;
        this.nombre = nombre;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public static List<Etiqueta> findAll() {
        List<Etiqueta> lista = new ArrayList<>();
        String sql = "SELECT id, nombre FROM etiqueta";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new Etiqueta(
                    rs.getInt("id"),
                    rs.getString("nombre")
                ));
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return lista;
    }

    public static Etiqueta findById(int idBuscado) {
        String sql = "SELECT id, nombre FROM etiqueta WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idBuscado);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Etiqueta(
                        rs.getInt("id"),
                        rs.getString("nombre")
                    );
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean save() {
        String sql = "INSERT INTO etiqueta(nombre) VALUES(?)";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, nombre);
            if (ps.executeUpdate() == 1) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        this.id = rs.getInt(1);
                    }
                }
                return true;
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }
    
    

    public boolean update() {
        String sql = "UPDATE etiqueta SET nombre = ? WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nombre);
            ps.setInt(2, id);
            return ps.executeUpdate() == 1;
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }

    public boolean delete() {
        String sql = "DELETE FROM etiqueta WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() == 1;
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }
}
