package clasesGenericas;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import ConexionBD.conexionBD;

public class RolPermiso {
    private int rolId;
    private int permisoId;

    public RolPermiso() { }

    public RolPermiso(int rolId, int permisoId) {
        this.rolId     = rolId;
        this.permisoId = permisoId;
    }

    public int getRolId() {
        return rolId;
    }

    public void setRolId(int rolId) {
        this.rolId = rolId;
    }

    public int getPermisoId() {
        return permisoId;
    }

    public void setPermisoId(int permisoId) {
        this.permisoId = permisoId;
    }

    public boolean save() {
        String sql = "INSERT INTO rol_permiso(rol_id, permiso_id) VALUES(?,?)";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, rolId);
            ps.setInt(2, permisoId);
            return ps.executeUpdate() == 1;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

 
    public boolean delete() {
        String sql = "DELETE FROM rol_permiso WHERE rol_id = ? AND permiso_id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, rolId);
            ps.setInt(2, permisoId);
            return ps.executeUpdate() == 1;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    
    public static List<RolPermiso> findAll() {
        List<RolPermiso> lista = new ArrayList<>();
        String sql = "SELECT rol_id, permiso_id FROM rol_permiso";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new RolPermiso(
                    rs.getInt("rol_id"),
                    rs.getInt("permiso_id")
                ));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return lista;
    }


    public static List<RolPermiso> findByRolId(int rolId) {
        List<RolPermiso> lista = new ArrayList<>();
        String sql = "SELECT rol_id, permiso_id FROM rol_permiso WHERE rol_id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, rolId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new RolPermiso(
                        rs.getInt("rol_id"),
                        rs.getInt("permiso_id")
                    ));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return lista;
    }

 
    public static List<RolPermiso> findByPermisoId(int permisoId) {
        List<RolPermiso> lista = new ArrayList<>();
        String sql = "SELECT rol_id, permiso_id FROM rol_permiso WHERE permiso_id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, permisoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new RolPermiso(
                        rs.getInt("rol_id"),
                        rs.getInt("permiso_id")
                    ));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return lista;
    }
}
