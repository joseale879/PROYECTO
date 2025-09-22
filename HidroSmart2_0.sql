-- ===============================
-- CREACIÓN BASE DE DATOS
-- ===============================
CREATE DATABASE HidroSmart2_0;
GO
USE HidroSmart2_0;
GO

-- ===============================
-- TABLAS PRINCIPALES
-- ===============================
CREATE TABLE Usuarios (
    UsuarioID INT PRIMARY KEY IDENTITY,
    NombreUsuario NVARCHAR(255) NOT NULL,
    Contraseña NVARCHAR(255) NOT NULL,
    EstadoUsuario BIT DEFAULT 1, -- 1 activo, 0 inactivo
    FechaCreacion DATETIME DEFAULT GETDATE(),
    UltimoAcceso DATETIME
);

CREATE TABLE Roles (
    RolID INT PRIMARY KEY IDENTITY,
    NombreRol NVARCHAR(50) NOT NULL,
    Descripcion NVARCHAR(255)
);

CREATE TABLE Usuario_Rol (
    UsuarioID INT,
    RolID INT,
    FechaAsignacion DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (UsuarioID, RolID),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID),
    FOREIGN KEY (RolID) REFERENCES Roles(RolID)
);

CREATE TABLE Permisos (
    PermisoID INT PRIMARY KEY IDENTITY,
    NombrePermiso NVARCHAR(50) NOT NULL,
    Descripcion NVARCHAR(255)
);

CREATE TABLE Rol_Permiso (
    RolID INT,
    PermisoID INT,
    FechaAsignacion DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (RolID, PermisoID),
    FOREIGN KEY (RolID) REFERENCES Roles(RolID),
    FOREIGN KEY (PermisoID) REFERENCES Permisos(PermisoID)
);

CREATE TABLE Configuracion_Seguridad (
    ConfiguracionID INT PRIMARY KEY IDENTITY,
    NombreConfiguracion NVARCHAR(100),
    ValorConfiguracion NVARCHAR(100),
    Descripcion NVARCHAR(255)
);

CREATE TABLE Log_Errores (
    ErrorID INT PRIMARY KEY IDENTITY,
    Fecha DATETIME DEFAULT GETDATE(),
    UsuarioID INT,
    TipoError NVARCHAR(100),
    Descripcion NVARCHAR(500),
    IP_Origen NVARCHAR(50),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

CREATE TABLE Politicas_Contraseñas (
    PoliticaID INT PRIMARY KEY IDENTITY,
    MinLongitud INT DEFAULT 8,
    MaxLongitud INT DEFAULT 20,
    RequiereMayusculas BIT DEFAULT 1,
    RequiereNumeros BIT DEFAULT 1,
    RequiereSimbolos BIT DEFAULT 1
);

-- ===============================
-- TABLAS DE DISPOSITIVOS
-- ===============================
CREATE TABLE Medidores (
    MedidorID INT PRIMARY KEY IDENTITY,
    Tipo NVARCHAR(50),
    Ubicacion NVARCHAR(100),
    Estado BIT DEFAULT 1
);

CREATE TABLE Sensores (
    SensorID INT PRIMARY KEY IDENTITY,
    Tipo NVARCHAR(50),
    MedidorID INT,
    Estado BIT DEFAULT 1,
    FOREIGN KEY (MedidorID) REFERENCES Medidores(MedidorID)
);

CREATE TABLE Actuadores (
    ActuadorID INT PRIMARY KEY IDENTITY,
    Tipo NVARCHAR(50),
    MedidorID INT,
    Estado BIT DEFAULT 1,
    FOREIGN KEY (MedidorID) REFERENCES Medidores(MedidorID)
);

-- ===============================
-- TABLAS DE OPERACIÓN
-- ===============================
CREATE TABLE Consumo (
    ConsumoID INT PRIMARY KEY IDENTITY,
    UsuarioID INT,
    MedidorID INT,
    Fecha DATETIME DEFAULT GETDATE(),
    Valor DECIMAL(10,2),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID),
    FOREIGN KEY (MedidorID) REFERENCES Medidores(MedidorID)
);

CREATE TABLE Notificaciones (
    NotificacionID INT PRIMARY KEY IDENTITY,
    UsuarioID INT,
    Mensaje NVARCHAR(255),
    Fecha DATETIME DEFAULT GETDATE(),
    Estado BIT DEFAULT 0, -- 0 no leída, 1 leída
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

CREATE TABLE Historial (
    HistorialID INT PRIMARY KEY IDENTITY,
    UsuarioID INT,
    MedidorID INT,
    Accion NVARCHAR(100),
    Fecha DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID),
    FOREIGN KEY (MedidorID) REFERENCES Medidores(MedidorID)
);

-- ===============================
-- ÍNDICES
-- ===============================
CREATE INDEX IX_Usuarios_NombreUsuario ON Usuarios(NombreUsuario);
CREATE INDEX IX_LogErrores_UsuarioID ON Log_Errores(UsuarioID);
CREATE INDEX IX_Consumo_Fecha ON Consumo(Fecha);
CREATE INDEX IX_Notificaciones_UsuarioID ON Notificaciones(UsuarioID);

-- ===============================
-- VISTAS
-- ===============================
CREATE VIEW Vista_UsuariosActivos AS
SELECT UsuarioID, NombreUsuario, FechaCreacion
FROM Usuarios
WHERE EstadoUsuario = 1;

CREATE VIEW Vista_ConsumoPorUsuario AS
SELECT u.NombreUsuario, SUM(c.Valor) AS TotalConsumo
FROM Consumo c
JOIN Usuarios u ON c.UsuarioID = u.UsuarioID
GROUP BY u.NombreUsuario;

CREATE VIEW Vista_NotificacionesPendientes AS
SELECT u.NombreUsuario, n.Mensaje, n.Fecha
FROM Notificaciones n
JOIN Usuarios u ON n.UsuarioID = u.UsuarioID
WHERE n.Estado = 0;

CREATE VIEW Vista_MedidoresActivos AS
SELECT MedidorID, Tipo, Ubicacion
FROM Medidores
WHERE Estado = 1;

CREATE VIEW Vista_HistorialAcciones AS
SELECT h.HistorialID, u.NombreUsuario, m.Tipo AS Medidor, h.Accion, h.Fecha
FROM Historial h
JOIN Usuarios u ON h.UsuarioID = u.UsuarioID
JOIN Medidores m ON h.MedidorID = m.MedidorID;

-- ===============================
-- PROCEDIMIENTO ALMACENADO
-- ===============================
CREATE PROCEDURE RegistrarConsumo
    @UsuarioID INT,
    @MedidorID INT,
    @Valor DECIMAL(10,2)
AS
BEGIN
    INSERT INTO Consumo (UsuarioID, MedidorID, Valor)
    VALUES (@UsuarioID, @MedidorID, @Valor);
END;
GO

-- ===============================
-- INSERCIÓN DE DATOS DE PRUEBA
-- ===============================
INSERT INTO Usuarios (NombreUsuario, Contraseña) VALUES
('admin', '12345'),
('juan', 'abc123'),
('maria', 'pass2025');

INSERT INTO Roles (NombreRol, Descripcion) VALUES
('Administrador', 'Control total del sistema'),
('Operador', 'Monitorea medidores y sensores'),
('Usuario', 'Accede a su consumo y notificaciones');

INSERT INTO Permisos (NombrePermiso, Descripcion) VALUES
('SELECT', 'Permite leer datos'),
('INSERT', 'Permite insertar datos'),
('UPDATE', 'Permite actualizar datos'),
('DELETE', 'Permite eliminar datos');

INSERT INTO Usuario_Rol (UsuarioID, RolID) VALUES
(1, 1), -- admin -> Administrador
(2, 3), -- juan -> Usuario
(3, 3); -- maria -> Usuario

INSERT INTO Rol_Permiso (RolID, PermisoID) VALUES
(1,1),(1,2),(1,3),(1,4), -- Admin tiene todos
(2,1),(2,2), -- Operador puede leer e insertar
(3,1); -- Usuario solo puede leer

INSERT INTO Medidores (Tipo, Ubicacion) VALUES
('Caudalímetro', 'Sector Norte'),
('Presión', 'Sector Sur');

INSERT INTO Sensores (Tipo, MedidorID) VALUES
('Humedad', 1),
('Temperatura', 2);

INSERT INTO Actuadores (Tipo, MedidorID) VALUES
('Válvula', 1),
('Bomba', 2);

INSERT INTO Consumo (UsuarioID, MedidorID, Valor) VALUES
(2, 1, 150.75),
(3, 2, 80.50);

INSERT INTO Notificaciones (UsuarioID, Mensaje) VALUES
(2, 'Alerta: Consumo elevado detectado'),
(3, 'Notificación: Nuevo registro de consumo disponible');

INSERT INTO Historial (UsuarioID, MedidorID, Accion) VALUES
(1, 1, 'Revisión de sensor'),
(2, 1, 'Consumo registrado'),
(3, 2, 'Consumo registrado');
