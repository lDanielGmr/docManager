package clasesGenericas;

import ConexionBD.conexionBD;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;


public class Usuario {
    private int id;
    private String nombre;
    private String usuario;
    private String contraseña;
    private Rol rol;
    private Integer idArea; 

    public Usuario() {}

    public Usuario(int id, String nombre, String usuario, String contraseña, Rol rol, Integer idArea) {
        this.id = id;
        this.nombre = nombre;
        this.usuario = usuario;
        this.contraseña = contraseña;
        this.rol = rol;
        this.idArea = idArea;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getUsuario() { return usuario; }
    public void setUsuario(String usuario) { this.usuario = usuario; }

    public String getContraseña() { return contraseña; }
    public void setContraseña(String contraseña) { this.contraseña = contraseña; }

    public Rol getRol() { return rol; }
    public void setRol(Rol rol) { this.rol = rol; }

    public Integer getIdArea() { return idArea; }
    public void setIdArea(Integer idArea) { this.idArea = idArea; }

   
    public String getArea() throws SQLException {
        if (idArea == null) return null;
        Area a = Area.findById(idArea);
        return a != null ? a.getNombre() : null;
    }

    @Override
    public String toString() {
        return "Usuario{id=" + id + ", usuario='" + usuario + "', nombre='" + nombre + "', rol=" + rol + ", idArea=" + idArea + "}";
    }

    private static Usuario mapRow(ResultSet rs) throws SQLException {
        Usuario u = new Usuario();
        u.setId(rs.getInt("id"));
        u.setNombre(rs.getString("nombre"));
        u.setUsuario(rs.getString("usuario"));
        u.setContraseña(rs.getString("contraseña"));
        u.setRol(Rol.findById(rs.getInt("id_rol")));
        int areaVal = rs.getInt("id_area");
        if (!rs.wasNull()) u.setIdArea(areaVal);
        return u;
    }

 
    public static List<Usuario> findAll() throws SQLException {
        String sql = "SELECT id, nombre, usuario, contraseña, id_rol, id_area FROM usuario";
        List<Usuario> list = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

 
    public static Usuario findByUsuario(String uname) throws SQLException {
        String sql = "SELECT id, nombre, usuario, contraseña, id_rol, id_area FROM usuario WHERE usuario = ?";
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, uname);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        }
        return null;
    }

 
    public void saveOrUpdate() throws SQLException {
        if (this.id == 0) {
            String sql = "INSERT INTO usuario (nombre, usuario, contraseña, id_rol, id_area) VALUES (?,?,?,?,?)";
            try (Connection c = conexionBD.conectar();
                 PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, this.nombre);
                ps.setString(2, this.usuario);
                ps.setString(3, this.contraseña);
                ps.setInt(4, this.rol.getId());
                if (idArea != null) ps.setInt(5, idArea);
                else ps.setNull(5, Types.INTEGER);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) this.id = keys.getInt(1);
                }
            }
        } else {
            String sql = "UPDATE usuario SET nombre=?, usuario=?, contraseña=?, id_rol=?, id_area=? WHERE id=?";
            try (Connection c = conexionBD.conectar();
                 PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, this.nombre);
                ps.setString(2, this.usuario);
                ps.setString(3, this.contraseña);
                ps.setInt(4, this.rol.getId());
                if (idArea != null) ps.setInt(5, idArea);
                else ps.setNull(5, Types.INTEGER);
                ps.setInt(6, this.id);
                ps.executeUpdate();
            }
        }
    }


    public void delete() throws SQLException {
        String sql = "DELETE FROM usuario WHERE id = ?";
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, this.id);
            ps.executeUpdate();
        }
    }
}
