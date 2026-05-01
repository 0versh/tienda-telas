--
-- PostgreSQL database dump
--

\restrict xmkPz6a8vL3vRmXJ1UgKwAya37bLY4AdYyEhRbZxegSu6R1CSBpzRnVtSyLWd3n

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-05-01 01:26:54

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 254 (class 1255 OID 17032)
-- Name: actualizar_stock_compra(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.actualizar_stock_compra() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_contador INT;
    v_numero_rollo VARCHAR(50);
BEGIN
    v_contador := 1;
    WHILE v_contador <= NEW.cantidad_rollos LOOP
        v_numero_rollo := NEW.id_tela || '-' || TO_CHAR(NEW.id_compra, 'FM0000') || '-' || TO_CHAR(v_contador, 'FM00');
        
        INSERT INTO inventario_rollos (
            id_tela, id_color, numero_rollo, metros_iniciales, metros_actuales, estado, ubicacion_estante
        ) VALUES (
            NEW.id_tela, NEW.id_color, v_numero_rollo, NEW.metros_por_rollo, NEW.metros_por_rollo, 'completo', 'Pendiente'
        );
        
        v_contador := v_contador + 1;
    END LOOP;
    
    UPDATE telas 
    SET stock_total_metros = stock_total_metros + (NEW.cantidad_rollos * NEW.metros_por_rollo)
    WHERE id_tela = NEW.id_tela;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.actualizar_stock_compra() OWNER TO postgres;

--
-- TOC entry 262 (class 1255 OID 17034)
-- Name: actualizar_stock_venta(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.actualizar_stock_venta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_venta_usr INT;
BEGIN
    SELECT id_usuario INTO v_id_venta_usr FROM ventas WHERE id_venta = NEW.id_venta;
    
    UPDATE inventario_rollos 
    SET metros_actuales = metros_actuales - NEW.metros_cortados,
        estado = CASE 
            WHEN (metros_actuales - NEW.metros_cortados) <= 0 THEN 'agotado'
            WHEN (metros_actuales - NEW.metros_cortados) < metros_iniciales THEN 'iniciado'
            ELSE estado
        END
    WHERE id_rollo = NEW.id_rollo;
    
    UPDATE telas 
    SET stock_total_metros = stock_total_metros - NEW.metros_cortados
    WHERE id_tela = NEW.id_tela;
    
    INSERT INTO movimientos_inventario (
        id_rollo, id_tela, tipo_movimiento, cantidad_metros, id_usuario, id_referencia, tipo_referencia, motivo
    ) VALUES (
        NEW.id_rollo, NEW.id_tela, 'salida_venta', NEW.metros_cortados, v_id_venta_usr, NEW.id_venta, 'venta', 'Venta de tela'
    );
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.actualizar_stock_venta() OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 24680)
-- Name: actualizar_total_pagar(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.actualizar_total_pagar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.total_pagar = NEW.subtotal - COALESCE(NEW.descuento, 0) + COALESCE(NEW.iva, 0);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.actualizar_total_pagar() OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 24682)
-- Name: actualizar_venta_desde_cortes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.actualizar_venta_desde_cortes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_venta INTEGER;
BEGIN
    -- Determinar el ID de la venta afectada
    IF TG_OP = 'DELETE' THEN
        v_id_venta = OLD.id_venta;
    ELSE
        v_id_venta = NEW.id_venta;
    END IF;
    
    -- Actualizar la venta
    UPDATE ventas SET
        total_metros = (
            SELECT COALESCE(SUM(metros_cortados), 0) 
            FROM cortes_ventas 
            WHERE id_venta = v_id_venta
        ),
        subtotal = (
            SELECT COALESCE(SUM(metros_cortados * precio_metro_momento), 0) 
            FROM cortes_ventas 
            WHERE id_venta = v_id_venta
        )
    WHERE id_venta = v_id_venta;
    
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.actualizar_venta_desde_cortes() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 232 (class 1259 OID 16856)
-- Name: clientes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clientes (
    id_cliente integer NOT NULL,
    nombre_cliente character varying(100) NOT NULL,
    tipo_documento character varying(20),
    numero_documento character varying(30),
    telefono character varying(20),
    email character varying(100),
    direccion text,
    tipo_cliente character varying(20) DEFAULT 'minorista'::character varying,
    fecha_registro date DEFAULT CURRENT_DATE,
    activo boolean DEFAULT true,
    CONSTRAINT tipo_cliente_check CHECK (((tipo_cliente)::text = ANY ((ARRAY['mayorista'::character varying, 'minorista'::character varying])::text[])))
);


ALTER TABLE public.clientes OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16855)
-- Name: clientes_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clientes_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.clientes_id_cliente_seq OWNER TO postgres;

--
-- TOC entry 5241 (class 0 OID 0)
-- Dependencies: 231
-- Name: clientes_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clientes_id_cliente_seq OWNED BY public.clientes.id_cliente;


--
-- TOC entry 224 (class 1259 OID 16759)
-- Name: colores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.colores (
    id_color integer NOT NULL,
    nombre_color character varying(50) NOT NULL,
    codigo_color character varying(20),
    descripcion text
);


ALTER TABLE public.colores OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16758)
-- Name: colores_id_color_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.colores_id_color_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.colores_id_color_seq OWNER TO postgres;

--
-- TOC entry 5242 (class 0 OID 0)
-- Dependencies: 223
-- Name: colores_id_color_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.colores_id_color_seq OWNED BY public.colores.id_color;


--
-- TOC entry 234 (class 1259 OID 16871)
-- Name: compras_proveedor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.compras_proveedor (
    id_compra integer NOT NULL,
    id_proveedor integer NOT NULL,
    fecha_compra date DEFAULT CURRENT_DATE NOT NULL,
    numero_factura character varying(50),
    total_metros numeric(10,2) NOT NULL,
    total_pagar numeric(10,2) NOT NULL,
    estado_pago character varying(20) DEFAULT 'pendiente'::character varying,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_usuario_registra integer,
    observaciones text,
    CONSTRAINT estado_pago_check CHECK (((estado_pago)::text = ANY ((ARRAY['pendiente'::character varying, 'pagado'::character varying, 'parcial'::character varying])::text[])))
);


ALTER TABLE public.compras_proveedor OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16870)
-- Name: compras_proveedor_id_compra_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.compras_proveedor_id_compra_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.compras_proveedor_id_compra_seq OWNER TO postgres;

--
-- TOC entry 5243 (class 0 OID 0)
-- Dependencies: 233
-- Name: compras_proveedor_id_compra_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.compras_proveedor_id_compra_seq OWNED BY public.compras_proveedor.id_compra;


--
-- TOC entry 240 (class 1259 OID 16959)
-- Name: cortes_ventas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cortes_ventas (
    id_corte integer NOT NULL,
    id_venta integer NOT NULL,
    id_rollo integer,
    id_tela integer NOT NULL,
    metros_cortados numeric(10,2) NOT NULL,
    precio_metro_momento numeric(10,2) NOT NULL,
    subtotal numeric(10,2) GENERATED ALWAYS AS ((metros_cortados * precio_metro_momento)) STORED,
    CONSTRAINT metros_positivos CHECK ((metros_cortados > (0)::numeric))
);


ALTER TABLE public.cortes_ventas OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16958)
-- Name: cortes_ventas_id_corte_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cortes_ventas_id_corte_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cortes_ventas_id_corte_seq OWNER TO postgres;

--
-- TOC entry 5244 (class 0 OID 0)
-- Dependencies: 239
-- Name: cortes_ventas_id_corte_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cortes_ventas_id_corte_seq OWNED BY public.cortes_ventas.id_corte;


--
-- TOC entry 236 (class 1259 OID 16899)
-- Name: detalle_compras; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalle_compras (
    id_detalle_compra integer NOT NULL,
    id_compra integer NOT NULL,
    id_tela integer NOT NULL,
    id_color integer,
    cantidad_rollos integer NOT NULL,
    metros_por_rollo numeric(10,2) NOT NULL,
    precio_metro_compra numeric(10,2) NOT NULL,
    subtotal numeric(10,2) GENERATED ALWAYS AS ((((cantidad_rollos)::numeric * metros_por_rollo) * precio_metro_compra)) STORED
);


ALTER TABLE public.detalle_compras OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16898)
-- Name: detalle_compras_id_detalle_compra_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.detalle_compras_id_detalle_compra_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.detalle_compras_id_detalle_compra_seq OWNER TO postgres;

--
-- TOC entry 5245 (class 0 OID 0)
-- Dependencies: 235
-- Name: detalle_compras_id_detalle_compra_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.detalle_compras_id_detalle_compra_seq OWNED BY public.detalle_compras.id_detalle_compra;


--
-- TOC entry 228 (class 1259 OID 16805)
-- Name: inventario_rollos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario_rollos (
    id_rollo integer NOT NULL,
    id_tela integer NOT NULL,
    id_color integer,
    numero_rollo character varying(50) NOT NULL,
    metros_iniciales numeric(10,2) NOT NULL,
    metros_actuales numeric(10,2) NOT NULL,
    estado character varying(20) DEFAULT 'completo'::character varying,
    fecha_ingreso date DEFAULT CURRENT_DATE,
    ubicacion_estante character varying(50),
    observaciones text,
    codigo_rfid character varying(50),
    CONSTRAINT estado_check CHECK (((estado)::text = ANY ((ARRAY['completo'::character varying, 'iniciado'::character varying, 'agotado'::character varying])::text[]))),
    CONSTRAINT metros_actuales_check CHECK ((metros_actuales >= (0)::numeric))
);


ALTER TABLE public.inventario_rollos OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16804)
-- Name: inventario_rollos_id_rollo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_rollos_id_rollo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_rollos_id_rollo_seq OWNER TO postgres;

--
-- TOC entry 5246 (class 0 OID 0)
-- Dependencies: 227
-- Name: inventario_rollos_id_rollo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_rollos_id_rollo_seq OWNED BY public.inventario_rollos.id_rollo;


--
-- TOC entry 247 (class 1259 OID 24577)
-- Name: logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.logs (
    id_log integer NOT NULL,
    usuario_id integer,
    accion character varying(100) NOT NULL,
    modulo character varying(50) NOT NULL,
    detalle text,
    ip character varying(45),
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.logs OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 24576)
-- Name: logs_id_log_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.logs_id_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logs_id_log_seq OWNER TO postgres;

--
-- TOC entry 5247 (class 0 OID 0)
-- Dependencies: 246
-- Name: logs_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.logs_id_log_seq OWNED BY public.logs.id_log;


--
-- TOC entry 242 (class 1259 OID 16988)
-- Name: movimientos_inventario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimientos_inventario (
    id_movimiento integer NOT NULL,
    id_rollo integer,
    id_tela integer NOT NULL,
    tipo_movimiento character varying(30) NOT NULL,
    cantidad_metros numeric(10,2) NOT NULL,
    fecha_movimiento timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_usuario integer,
    id_referencia integer,
    tipo_referencia character varying(20),
    motivo text,
    CONSTRAINT tipo_movimiento_check CHECK (((tipo_movimiento)::text = ANY ((ARRAY['entrada_compra'::character varying, 'salida_venta'::character varying, 'ajuste_inventario'::character varying, 'devolucion'::character varying])::text[])))
);


ALTER TABLE public.movimientos_inventario OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16987)
-- Name: movimientos_inventario_id_movimiento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.movimientos_inventario_id_movimiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.movimientos_inventario_id_movimiento_seq OWNER TO postgres;

--
-- TOC entry 5248 (class 0 OID 0)
-- Dependencies: 241
-- Name: movimientos_inventario_id_movimiento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.movimientos_inventario_id_movimiento_seq OWNED BY public.movimientos_inventario.id_movimiento;


--
-- TOC entry 220 (class 1259 OID 16733)
-- Name: proveedores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.proveedores (
    id_proveedor integer NOT NULL,
    nombre_proveedor character varying(100) NOT NULL,
    contacto character varying(100),
    telefono character varying(20),
    email character varying(100),
    direccion text,
    tipo_telas_suministra text,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    activo boolean DEFAULT true
);


ALTER TABLE public.proveedores OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16732)
-- Name: proveedores_id_proveedor_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.proveedores_id_proveedor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.proveedores_id_proveedor_seq OWNER TO postgres;

--
-- TOC entry 5249 (class 0 OID 0)
-- Dependencies: 219
-- Name: proveedores_id_proveedor_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.proveedores_id_proveedor_seq OWNED BY public.proveedores.id_proveedor;


--
-- TOC entry 226 (class 1259 OID 16772)
-- Name: telas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.telas (
    id_tela integer NOT NULL,
    codigo_tela character varying(30) NOT NULL,
    nombre_tela character varying(100) NOT NULL,
    id_tipo integer NOT NULL,
    id_proveedor integer NOT NULL,
    composicion character varying(200),
    ancho numeric(10,2),
    peso_gramaje numeric(10,2),
    precio_compra_metro numeric(10,2) NOT NULL,
    precio_venta_metro numeric(10,2) NOT NULL,
    stock_total_metros numeric(10,2) DEFAULT 0,
    stock_minimo_metros numeric(10,2) DEFAULT 10,
    ubicacion_general character varying(50),
    imagen_referencia text,
    fecha_ingreso date DEFAULT CURRENT_DATE,
    activo boolean DEFAULT true,
    CONSTRAINT stock_positivo CHECK ((stock_total_metros >= (0)::numeric))
);


ALTER TABLE public.telas OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16771)
-- Name: telas_id_tela_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.telas_id_tela_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.telas_id_tela_seq OWNER TO postgres;

--
-- TOC entry 5250 (class 0 OID 0)
-- Dependencies: 225
-- Name: telas_id_tela_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.telas_id_tela_seq OWNED BY public.telas.id_tela;


--
-- TOC entry 222 (class 1259 OID 16746)
-- Name: tipos_de_tela; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_de_tela (
    id_tipo integer NOT NULL,
    nombre_tipo character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE public.tipos_de_tela OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16745)
-- Name: tipos_de_tela_id_tipo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipos_de_tela_id_tipo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipos_de_tela_id_tipo_seq OWNER TO postgres;

--
-- TOC entry 5251 (class 0 OID 0)
-- Dependencies: 221
-- Name: tipos_de_tela_id_tipo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipos_de_tela_id_tipo_seq OWNED BY public.tipos_de_tela.id_tipo;


--
-- TOC entry 230 (class 1259 OID 16835)
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id_usuario integer NOT NULL,
    nombre_completo character varying(100) NOT NULL,
    nombre_usuario character varying(50) NOT NULL,
    contrasena_hash character varying(255) NOT NULL,
    email character varying(100),
    rol character varying(20) DEFAULT 'vendedor'::character varying,
    activo boolean DEFAULT true,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ultimo_acceso timestamp without time zone,
    CONSTRAINT rol_check CHECK (((rol)::text = ANY ((ARRAY['admin'::character varying, 'vendedor'::character varying, 'supervisor'::character varying])::text[])))
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16834)
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuarios_id_usuario_seq OWNER TO postgres;

--
-- TOC entry 5252 (class 0 OID 0)
-- Dependencies: 229
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_usuario_seq OWNED BY public.usuarios.id_usuario;


--
-- TOC entry 238 (class 1259 OID 16928)
-- Name: ventas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ventas (
    id_venta integer NOT NULL,
    fecha_venta timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_usuario integer NOT NULL,
    id_cliente integer,
    total_metros numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    descuento numeric(10,2) DEFAULT 0,
    iva numeric(10,2) DEFAULT 0,
    total_pagar numeric(10,2) NOT NULL,
    metodo_pago character varying(30),
    estado character varying(20) DEFAULT 'completada'::character varying,
    observaciones text,
    CONSTRAINT estado_venta_check CHECK (((estado)::text = ANY ((ARRAY['completada'::character varying, 'anulada'::character varying, 'pendiente'::character varying])::text[]))),
    CONSTRAINT metodo_pago_check CHECK (((metodo_pago)::text = ANY ((ARRAY['efectivo'::character varying, 'tarjeta'::character varying, 'transferencia'::character varying, 'mixto'::character varying])::text[])))
);


ALTER TABLE public.ventas OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16927)
-- Name: ventas_id_venta_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ventas_id_venta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ventas_id_venta_seq OWNER TO postgres;

--
-- TOC entry 5253 (class 0 OID 0)
-- Dependencies: 237
-- Name: ventas_id_venta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ventas_id_venta_seq OWNED BY public.ventas.id_venta;


--
-- TOC entry 243 (class 1259 OID 17036)
-- Name: vista_inventario_actual; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_inventario_actual AS
 SELECT t.codigo_tela,
    t.nombre_tela,
    tp.nombre_tipo AS tipo_tela,
    c.nombre_color AS color,
    ir.numero_rollo,
    ir.metros_actuales,
    ir.estado,
    ir.ubicacion_estante,
    p.nombre_proveedor,
    t.precio_venta_metro
   FROM ((((public.inventario_rollos ir
     JOIN public.telas t ON ((ir.id_tela = t.id_tela)))
     JOIN public.tipos_de_tela tp ON ((t.id_tipo = tp.id_tipo)))
     LEFT JOIN public.colores c ON ((ir.id_color = c.id_color)))
     JOIN public.proveedores p ON ((t.id_proveedor = p.id_proveedor)))
  WHERE (ir.metros_actuales > (0)::numeric)
  ORDER BY t.nombre_tela, ir.numero_rollo;


ALTER VIEW public.vista_inventario_actual OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 17041)
-- Name: vista_stock_critico; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_stock_critico AS
 SELECT t.codigo_tela,
    t.nombre_tela,
    t.stock_total_metros,
    t.stock_minimo_metros,
    p.nombre_proveedor,
    t.precio_venta_metro
   FROM (public.telas t
     JOIN public.proveedores p ON ((t.id_proveedor = p.id_proveedor)))
  WHERE ((t.stock_total_metros <= t.stock_minimo_metros) AND (t.activo = true));


ALTER VIEW public.vista_stock_critico OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 17046)
-- Name: vista_ventas_resumen; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_ventas_resumen AS
 SELECT date(v.fecha_venta) AS fecha,
    count(DISTINCT v.id_venta) AS total_ventas,
    sum(v.total_metros) AS metros_vendidos,
    sum(v.total_pagar) AS ingresos_totales,
    u.nombre_usuario
   FROM (public.ventas v
     JOIN public.usuarios u ON ((v.id_usuario = u.id_usuario)))
  WHERE ((v.estado)::text = 'completada'::text)
  GROUP BY (date(v.fecha_venta)), u.nombre_usuario;


ALTER VIEW public.vista_ventas_resumen OWNER TO postgres;

--
-- TOC entry 4949 (class 2604 OID 16859)
-- Name: clientes id_cliente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes ALTER COLUMN id_cliente SET DEFAULT nextval('public.clientes_id_cliente_seq'::regclass);


--
-- TOC entry 4936 (class 2604 OID 16762)
-- Name: colores id_color; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.colores ALTER COLUMN id_color SET DEFAULT nextval('public.colores_id_color_seq'::regclass);


--
-- TOC entry 4953 (class 2604 OID 16874)
-- Name: compras_proveedor id_compra; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compras_proveedor ALTER COLUMN id_compra SET DEFAULT nextval('public.compras_proveedor_id_compra_seq'::regclass);


--
-- TOC entry 4964 (class 2604 OID 16962)
-- Name: cortes_ventas id_corte; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cortes_ventas ALTER COLUMN id_corte SET DEFAULT nextval('public.cortes_ventas_id_corte_seq'::regclass);


--
-- TOC entry 4957 (class 2604 OID 16902)
-- Name: detalle_compras id_detalle_compra; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_compras ALTER COLUMN id_detalle_compra SET DEFAULT nextval('public.detalle_compras_id_detalle_compra_seq'::regclass);


--
-- TOC entry 4942 (class 2604 OID 16808)
-- Name: inventario_rollos id_rollo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_rollos ALTER COLUMN id_rollo SET DEFAULT nextval('public.inventario_rollos_id_rollo_seq'::regclass);


--
-- TOC entry 4968 (class 2604 OID 24580)
-- Name: logs id_log; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs ALTER COLUMN id_log SET DEFAULT nextval('public.logs_id_log_seq'::regclass);


--
-- TOC entry 4966 (class 2604 OID 16991)
-- Name: movimientos_inventario id_movimiento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario ALTER COLUMN id_movimiento SET DEFAULT nextval('public.movimientos_inventario_id_movimiento_seq'::regclass);


--
-- TOC entry 4932 (class 2604 OID 16736)
-- Name: proveedores id_proveedor; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedores ALTER COLUMN id_proveedor SET DEFAULT nextval('public.proveedores_id_proveedor_seq'::regclass);


--
-- TOC entry 4937 (class 2604 OID 16775)
-- Name: telas id_tela; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telas ALTER COLUMN id_tela SET DEFAULT nextval('public.telas_id_tela_seq'::regclass);


--
-- TOC entry 4935 (class 2604 OID 16749)
-- Name: tipos_de_tela id_tipo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_de_tela ALTER COLUMN id_tipo SET DEFAULT nextval('public.tipos_de_tela_id_tipo_seq'::regclass);


--
-- TOC entry 4945 (class 2604 OID 16838)
-- Name: usuarios id_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuarios_id_usuario_seq'::regclass);


--
-- TOC entry 4959 (class 2604 OID 16931)
-- Name: ventas id_venta; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas ALTER COLUMN id_venta SET DEFAULT nextval('public.ventas_id_venta_seq'::regclass);


--
-- TOC entry 5223 (class 0 OID 16856)
-- Dependencies: 232
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clientes (id_cliente, nombre_cliente, tipo_documento, numero_documento, telefono, email, direccion, tipo_cliente, fecha_registro, activo) FROM stdin;
1	María López	DNI	12345678	555-2001	maria.lopez@email.com	Calle Flores 123	minorista	2026-03-16	t
2	Juan Carlos Mendoza	RUC	20123456789	555-2002	jcmendoza@empresa.com	Av. Industrial 456	mayorista	2026-03-16	t
3	Textiles Modernos SA	RUC	20987654321	555-2003	compras@textilesmodernos.com	Zona Industrial 789	mayorista	2026-03-16	t
4	Laura Fernández	DNI	87654321	555-2004	laura.f@email.com	Calle Luna 567	minorista	2026-03-16	t
5	Roberto Gómez	DNI	45678912	555-2005	roberto.g@email.com	Av. Sol 890	minorista	2026-03-16	t
\.


--
-- TOC entry 5215 (class 0 OID 16759)
-- Dependencies: 224
-- Data for Name: colores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.colores (id_color, nombre_color, codigo_color, descripcion) FROM stdin;
1	Blanco	#FFFFFF	\N
2	Negro	#000000	\N
3	Rojo	#FF0000	\N
4	Azul	#0000FF	\N
5	Verde	#00FF00	\N
6	Amarillo	#FFFF00	\N
7	Gris	#808080	\N
8	Beige	#F5F5DC	\N
9	Marrón	#8B4513	\N
10	Celeste	#87CEEB	\N
11	Rosa	#FFC0CB	\N
12	Morado	#800080	\N
13	Naranja	#FFA500	\N
14	Turquesa	#40E0D0	\N
\.


--
-- TOC entry 5225 (class 0 OID 16871)
-- Dependencies: 234
-- Data for Name: compras_proveedor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.compras_proveedor (id_compra, id_proveedor, fecha_compra, numero_factura, total_metros, total_pagar, estado_pago, fecha_registro, id_usuario_registra, observaciones) FROM stdin;
2	3	2026-05-01		30.00	900.00	pagado	2026-05-01 00:27:22.536765	1	
3	5	2026-05-01		12.00	2400.00	parcial	2026-05-01 00:33:41.610665	1	
\.


--
-- TOC entry 5231 (class 0 OID 16959)
-- Dependencies: 240
-- Data for Name: cortes_ventas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cortes_ventas (id_corte, id_venta, id_rollo, id_tela, metros_cortados, precio_metro_momento) FROM stdin;
1	1	25	23	2.00	19.99
2	2	23	22	4.00	18.50
3	2	26	24	4.00	28.00
4	2	13	16	1.00	9.99
5	3	15	18	3.00	35.00
6	4	14	17	2.00	10.50
7	4	15	18	2.00	35.00
8	5	18	20	2.00	28.00
10	9	5	14	1.00	14.50
11	10	5	14	2.00	14.50
12	11	6	14	1.00	14.50
13	11	2	13	3.00	12.99
14	12	19	21	3.33	13.50
15	13	7	15	1.00	15.99
16	14	2	13	1.00	12.99
17	15	22	22	1.00	18.50
18	16	5	14	1.00	14.50
19	17	5	14	5.00	14.50
20	18	5	14	1.00	14.50
21	19	27	14	1.00	14.50
\.


--
-- TOC entry 5227 (class 0 OID 16899)
-- Dependencies: 236
-- Data for Name: detalle_compras; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.detalle_compras (id_detalle_compra, id_compra, id_tela, id_color, cantidad_rollos, metros_por_rollo, precio_metro_compra) FROM stdin;
1	2	14	6	15	2.00	30.00
2	3	26	\N	12	1.00	200.00
\.


--
-- TOC entry 5219 (class 0 OID 16805)
-- Dependencies: 228
-- Data for Name: inventario_rollos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventario_rollos (id_rollo, id_tela, id_color, numero_rollo, metros_iniciales, metros_actuales, estado, fecha_ingreso, ubicacion_estante, observaciones, codigo_rfid) FROM stdin;
1	13	6	13-001	37.50	37.50	iniciado	2026-03-16	Estante D-01	\N	RFID-00000001
3	13	4	13-003	37.50	37.50	completo	2026-03-16	Estante D-03	\N	RFID-00000003
4	13	8	13-004	37.50	37.50	completo	2026-03-16	Estante D-04	\N	RFID-00000004
8	15	11	15-002	22.50	22.50	completo	2026-03-16	Estante A-02	\N	RFID-00000008
9	16	13	16-001	40.00	40.00	iniciado	2026-03-16	Estante B-01	\N	RFID-00000009
10	16	9	16-002	40.00	40.00	completo	2026-03-16	Estante B-02	\N	RFID-00000010
11	16	14	16-003	40.00	40.00	completo	2026-03-16	Estante B-03	\N	RFID-00000011
12	16	9	16-004	40.00	40.00	completo	2026-03-16	Estante B-04	\N	RFID-00000012
16	19	1	19-001	12.00	12.00	iniciado	2026-03-16	Estante E-01	\N	RFID-00000016
17	20	6	20-001	30.00	30.00	iniciado	2026-03-16	Estante A-01	\N	RFID-00000017
20	21	6	21-002	33.33	33.33	completo	2026-03-16	Estante B-02	\N	RFID-00000020
21	21	9	21-003	33.33	33.33	completo	2026-03-16	Estante B-03	\N	RFID-00000021
24	22	4	22-003	30.00	30.00	completo	2026-03-16	Estante C-03	\N	RFID-00000024
25	23	10	23-001	15.00	11.00	iniciado	2026-03-16	Estante D-01	\N	RFID-00000025
23	22	14	22-002	30.00	22.00	iniciado	2026-03-16	Estante C-02	\N	RFID-00000023
26	24	10	24-001	30.00	22.00	iniciado	2026-03-16	Estante E-01	\N	RFID-00000026
13	16	7	16-005	40.00	38.00	iniciado	2026-03-16	Estante B-05	\N	RFID-00000013
14	17	1	17-001	25.00	21.00	iniciado	2026-03-16	Estante C-01	\N	RFID-00000014
15	18	11	18-001	40.00	30.00	iniciado	2026-03-16	Estante D-01	\N	RFID-00000015
18	20	2	20-002	30.00	26.00	iniciado	2026-03-16	Estante A-02	\N	RFID-00000018
6	14	12	14-002	40.00	39.00	iniciado	2026-03-16	Estante E-02	\N	RFID-00000006
19	21	12	21-001	33.33	30.00	iniciado	2026-03-16	Estante B-01	\N	RFID-00000019
7	15	12	15-001	22.50	21.50	iniciado	2026-03-16	Estante A-01	\N	RFID-00000007
2	13	11	13-002	37.50	33.50	iniciado	2026-03-16	Estante D-02	\N	RFID-00000002
22	22	2	22-001	30.00	29.00	iniciado	2026-03-16	Estante C-01	\N	RFID-00000022
5	14	5	14-001	40.00	30.00	iniciado	2026-03-16	Estante E-01	\N	RFID-00000005
28	14	6	14-0002-02	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
29	14	6	14-0002-03	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
30	14	6	14-0002-04	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
31	14	6	14-0002-05	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
32	14	6	14-0002-06	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
33	14	6	14-0002-07	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
34	14	6	14-0002-08	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
35	14	6	14-0002-09	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
36	14	6	14-0002-10	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
37	14	6	14-0002-11	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
38	14	6	14-0002-12	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
39	14	6	14-0002-13	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
40	14	6	14-0002-14	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
41	14	6	14-0002-15	2.00	2.00	completo	2026-05-01	Pendiente	\N	\N
27	14	6	14-0002-01	2.00	1.00	iniciado	2026-05-01	Pendiente	\N	\N
42	26	\N	26-0003-01	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
43	26	\N	26-0003-02	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
44	26	\N	26-0003-03	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
45	26	\N	26-0003-04	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
46	26	\N	26-0003-05	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
47	26	\N	26-0003-06	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
48	26	\N	26-0003-07	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
49	26	\N	26-0003-08	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
50	26	\N	26-0003-09	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
51	26	\N	26-0003-10	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
52	26	\N	26-0003-11	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
53	26	\N	26-0003-12	1.00	1.00	completo	2026-05-01	Pendiente	\N	\N
\.


--
-- TOC entry 5235 (class 0 OID 24577)
-- Dependencies: 247
-- Data for Name: logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.logs (id_log, usuario_id, accion, modulo, detalle, ip, fecha) FROM stdin;
\.


--
-- TOC entry 5233 (class 0 OID 16988)
-- Dependencies: 242
-- Data for Name: movimientos_inventario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movimientos_inventario (id_movimiento, id_rollo, id_tela, tipo_movimiento, cantidad_metros, fecha_movimiento, id_usuario, id_referencia, tipo_referencia, motivo) FROM stdin;
1	25	23	salida_venta	2.00	2026-03-16 21:42:16.493918	1	1	venta	Venta de tela
2	23	22	salida_venta	4.00	2026-03-16 21:42:16.493918	1	2	venta	Venta de tela
3	26	24	salida_venta	4.00	2026-03-16 21:42:16.493918	1	2	venta	Venta de tela
4	13	16	salida_venta	1.00	2026-03-16 21:42:16.493918	1	2	venta	Venta de tela
5	15	18	salida_venta	3.00	2026-03-16 21:42:16.493918	1	3	venta	Venta de tela
6	14	17	salida_venta	2.00	2026-03-16 21:42:16.493918	1	4	venta	Venta de tela
7	15	18	salida_venta	2.00	2026-03-16 21:42:16.493918	1	4	venta	Venta de tela
8	18	20	salida_venta	2.00	2026-03-16 21:42:16.493918	1	5	venta	Venta de tela
9	5	14	salida_venta	1.00	2026-03-23 18:42:49.610594	1	9	venta	Venta de tela
10	5	14	salida_venta	2.00	2026-03-23 18:48:57.43481	1	10	venta	Venta de tela
11	6	14	salida_venta	1.00	2026-03-23 18:57:59.914071	1	11	venta	Venta de tela
12	2	13	salida_venta	3.00	2026-03-23 18:57:59.914071	1	11	venta	Venta de tela
13	19	21	salida_venta	3.33	2026-03-23 19:19:28.006012	1	12	venta	Venta de tela
14	7	15	salida_venta	1.00	2026-03-23 19:32:05.745196	1	13	venta	Venta de tela
15	2	13	salida_venta	1.00	2026-03-23 19:32:16.411707	1	14	venta	Venta de tela
16	22	22	salida_venta	1.00	2026-03-23 19:32:31.750212	1	15	venta	Venta de tela
17	5	14	salida_venta	1.00	2026-03-23 19:33:53.836496	1	16	venta	Venta de tela
18	5	14	salida_venta	5.00	2026-03-25 21:41:40.09474	1	17	venta	Venta de tela
19	5	14	salida_venta	1.00	2026-04-04 21:58:26.634477	1	18	venta	Venta de tela
20	27	14	salida_venta	1.00	2026-05-01 00:30:21.94843	1	19	venta	Venta de tela
\.


--
-- TOC entry 5211 (class 0 OID 16733)
-- Dependencies: 220
-- Data for Name: proveedores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.proveedores (id_proveedor, nombre_proveedor, contacto, telefono, email, direccion, tipo_telas_suministra, fecha_registro, activo) FROM stdin;
1	Textiles del Sur	Carlos Rodríguez	555-1001	carlos@textilessur.com	Av. Industrial 123	Algodón, Poliéster, Mezclas	2026-03-16 21:40:41.23548	t
2	Importaciones Textil World	María González	555-1002	maria@textilworld.com	Calle Comercio 456	Seda, Lino, Telas importadas	2026-03-16 21:40:41.23548	t
3	Distribuidora La Tela	Juan Pérez	555-1003	juan@latela.com	Blvd. Textil 789	Denim, Lona, Mezclilla	2026-03-16 21:40:41.23548	t
4	Telas Finas SA	Laura Martínez	555-1004	laura@telasfinas.com	Av. Principal 321	Seda, Terciopelo, Encajes	2026-03-16 21:40:41.23548	t
5	Mayorista Textil	Roberto Sánchez	555-1005	roberto@mayoristatextil.com	Calle Industria 654	Algodón, Poliéster, Franela	2026-03-16 21:40:41.23548	t
\.


--
-- TOC entry 5217 (class 0 OID 16772)
-- Dependencies: 226
-- Data for Name: telas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.telas (id_tela, codigo_tela, nombre_tela, id_tipo, id_proveedor, composicion, ancho, peso_gramaje, precio_compra_metro, precio_venta_metro, stock_total_metros, stock_minimo_metros, ubicacion_general, imagen_referencia, fecha_ingreso, activo) FROM stdin;
23	DEN-002	Mezclilla Negra	6	3	100% Algodón	1.60	320.00	8.50	19.99	13.00	25.00	Estante F2	\N	2026-03-16	t
14	ALG-002	Algodón Estampado Flores	1	1	100% Algodón	1.40	160.00	6.20	14.50	98.00	30.00	Estante A2	\N	2026-03-16	t
24	TER-001	Terciopelo Rojo	7	4	100% Poliéster	1.40	250.00	12.00	28.00	26.00	15.00	Estante G1	\N	2026-03-16	t
16	POL-001	Poliéster Brillante	2	1	100% Poliéster	1.50	120.00	4.00	9.99	199.00	30.00	Estante B1	\N	2026-03-16	t
26	123	TelarPrueba	6	2	95% algodon	124.00	123.00	1524.00	6743.00	12.00	11.00	\N	\N	2026-03-16	t
17	POL-002	Poliéster Opaco	2	5	100% Poliéster	1.50	130.00	4.50	10.50	23.00	30.00	Estante B2	\N	2026-03-16	t
18	SED-001	Seda Natural Lisa	3	3	100% Seda	1.20	80.00	15.00	35.00	35.00	15.00	Estante C1	\N	2026-03-16	t
20	LIN-001	Lino Natural	4	2	100% Lino	1.40	150.00	12.00	28.00	58.00	20.00	Estante D1	\N	2026-03-16	t
25	123456789	TelaPrueba	1	3	95% algodon	100.00	55.00	1500.00	2000.00	0.00	3.11	\N	\N	2026-03-16	f
21	MEZ-001	Mezcla Algodón-Poliéster	5	1	60% Algodón, 40% Poliéster	1.50	170.00	6.00	13.50	96.67	25.00	Estante E1	\N	2026-03-16	t
15	ALG-003	Algodón Jersey Negro	1	5	95% Algodón, 5% Elastano	1.60	200.00	7.00	15.99	44.00	40.00	Estante A3	\N	2026-03-16	t
13	ALG-001	Algodón Premium Blanco	1	1	100% Algodón	1.50	180.00	5.50	12.99	146.00	50.00	Estante A1	\N	2026-03-16	t
22	DEN-001	Mezclilla Azul	6	3	100% Algodón	1.60	300.00	8.00	18.50	85.00	25.00	Estante F1	\N	2026-03-16	t
28	Tela007	TelaNegra	2	3	75% poliester 	1.00	55.00	45.00	70.00	0.00	9.00	\N	\N	2026-03-25	t
19	SED-002	Seda Estampada	3	3	100% Seda	1.20	85.00	18.00	42.00	12.00	15.00	Estante C2	\N	2026-03-16	t
\.


--
-- TOC entry 5213 (class 0 OID 16746)
-- Dependencies: 222
-- Data for Name: tipos_de_tela; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_de_tela (id_tipo, nombre_tipo, descripcion) FROM stdin;
1	Algodón	Tela natural suave y transpirable
2	Poliéster	Tela sintética resistente y de secado rápido
3	Seda	Tela natural lujosa y brillante
4	Lino	Tela natural fresca ideal para verano
5	Mezcla	Combinación de fibras naturales y sintéticas
6	Denim	Tela resistente tipo jean
7	Terciopelo	Tela suave con textura aterciopelada
\.


--
-- TOC entry 5221 (class 0 OID 16835)
-- Dependencies: 230
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id_usuario, nombre_completo, nombre_usuario, contrasena_hash, email, rol, activo, fecha_registro, ultimo_acceso) FROM stdin;
1	Administrador	admin	scrypt:32768:8:1$ViHJa2mVVrNEype2$f6e4aa255b6bd63d2f7151eca82b43b427a41669f1e5169b22cbcbd237526119c1586a22b05422a09b48271b37c34f8a991b9ddac9816de7d8f3991fc60e0300	admin@tienda.com	admin	t	2026-03-16 21:39:33.157577	\N
3	1	Almacen	scrypt:32768:8:1$WhJJoDNRDdFXinvO$267817abec57d0f820608088eee5eb2c3994725eb14b0ee5a002c3055cd67361cc87fb4f5c284e5cab0a8f6075abb301fca7abd9b30af04bd575fa60edf5b6f6	almacen1@tiendadetelas.com	supervisor	t	2026-03-16 21:48:30.364165	\N
2	Vendedor Prueba	vendedor1	scrypt:32768:8:1$SO627qQj5i80OY7Y$1d7f5f6ceac372b2bdb1e4498b53042a1de7dfa67203223d95c1e09942bbf030cd8278174835d78b9626b9bec8d5be802177434c009bc7690aa5b1b8184cec8e	vendedor@tienda.com	vendedor	t	2026-03-16 21:44:32.978692	\N
\.


--
-- TOC entry 5229 (class 0 OID 16928)
-- Dependencies: 238
-- Data for Name: ventas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ventas (id_venta, fecha_venta, id_usuario, id_cliente, total_metros, subtotal, descuento, iva, total_pagar, metodo_pago, estado, observaciones) FROM stdin;
1	2026-03-12 07:21:14.360178	1	\N	2.00	39.98	0.00	0.00	39.98	tarjeta	completada	\N
2	2026-03-13 19:56:55.955866	1	4	9.00	195.99	0.00	0.00	195.99	efectivo	completada	\N
3	2026-03-06 06:47:15.960596	1	\N	3.00	105.00	0.00	0.00	105.00	efectivo	completada	\N
4	2026-03-08 18:38:11.704708	1	2	4.00	91.00	0.00	0.00	91.00	tarjeta	completada	\N
5	2026-03-15 06:15:32.726102	1	\N	2.00	56.00	0.00	0.00	56.00	efectivo	completada	\N
9	2026-03-23 18:42:49.610506	1	\N	1.00	14.50	0.00	0.00	14.50	efectivo	completada	\N
10	2026-03-23 18:48:57.434724	1	\N	2.00	29.00	10.00	0.00	19.00	efectivo	completada	\N
11	2026-03-23 18:57:59.914	1	\N	4.00	53.47	1.00	0.00	52.47	efectivo	completada	\N
12	2026-03-23 19:19:28.005937	1	\N	3.33	44.96	0.00	0.00	44.96	efectivo	completada	\N
13	2026-03-23 19:32:05.745122	1	\N	1.00	15.99	0.00	0.00	15.99	efectivo	completada	\N
14	2026-03-23 19:32:16.411616	1	\N	1.00	12.99	0.00	0.00	12.99	efectivo	completada	\N
15	2026-03-23 19:32:31.750141	1	\N	1.00	18.50	0.00	0.00	18.50	efectivo	completada	\N
16	2026-03-23 19:33:53.836416	1	\N	1.00	14.50	0.00	0.00	14.50	efectivo	completada	\N
17	2026-03-25 21:41:40.094646	1	\N	5.00	72.50	0.00	0.00	72.50	efectivo	completada	\N
18	2026-04-04 21:58:26.634379	1	\N	1.00	14.50	0.00	0.00	14.50	efectivo	completada	\N
19	2026-05-01 00:30:21.948361	1	\N	1.00	14.50	0.00	0.00	14.50	efectivo	completada	\N
\.


--
-- TOC entry 5254 (class 0 OID 0)
-- Dependencies: 231
-- Name: clientes_id_cliente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clientes_id_cliente_seq', 5, true);


--
-- TOC entry 5255 (class 0 OID 0)
-- Dependencies: 223
-- Name: colores_id_color_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.colores_id_color_seq', 14, true);


--
-- TOC entry 5256 (class 0 OID 0)
-- Dependencies: 233
-- Name: compras_proveedor_id_compra_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.compras_proveedor_id_compra_seq', 3, true);


--
-- TOC entry 5257 (class 0 OID 0)
-- Dependencies: 239
-- Name: cortes_ventas_id_corte_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cortes_ventas_id_corte_seq', 21, true);


--
-- TOC entry 5258 (class 0 OID 0)
-- Dependencies: 235
-- Name: detalle_compras_id_detalle_compra_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.detalle_compras_id_detalle_compra_seq', 2, true);


--
-- TOC entry 5259 (class 0 OID 0)
-- Dependencies: 227
-- Name: inventario_rollos_id_rollo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inventario_rollos_id_rollo_seq', 53, true);


--
-- TOC entry 5260 (class 0 OID 0)
-- Dependencies: 246
-- Name: logs_id_log_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.logs_id_log_seq', 1, false);


--
-- TOC entry 5261 (class 0 OID 0)
-- Dependencies: 241
-- Name: movimientos_inventario_id_movimiento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.movimientos_inventario_id_movimiento_seq', 20, true);


--
-- TOC entry 5262 (class 0 OID 0)
-- Dependencies: 219
-- Name: proveedores_id_proveedor_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.proveedores_id_proveedor_seq', 5, true);


--
-- TOC entry 5263 (class 0 OID 0)
-- Dependencies: 225
-- Name: telas_id_tela_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.telas_id_tela_seq', 28, true);


--
-- TOC entry 5264 (class 0 OID 0)
-- Dependencies: 221
-- Name: tipos_de_tela_id_tipo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipos_de_tela_id_tipo_seq', 7, true);


--
-- TOC entry 5265 (class 0 OID 0)
-- Dependencies: 229
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_usuario_seq', 3, true);


--
-- TOC entry 5266 (class 0 OID 0)
-- Dependencies: 237
-- Name: ventas_id_venta_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ventas_id_venta_seq', 19, true);


--
-- TOC entry 5015 (class 2606 OID 16869)
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id_cliente);


--
-- TOC entry 4987 (class 2606 OID 16770)
-- Name: colores colores_nombre_color_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.colores
    ADD CONSTRAINT colores_nombre_color_key UNIQUE (nombre_color);


--
-- TOC entry 4989 (class 2606 OID 16768)
-- Name: colores colores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.colores
    ADD CONSTRAINT colores_pkey PRIMARY KEY (id_color);


--
-- TOC entry 5017 (class 2606 OID 16887)
-- Name: compras_proveedor compras_proveedor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compras_proveedor
    ADD CONSTRAINT compras_proveedor_pkey PRIMARY KEY (id_compra);


--
-- TOC entry 5028 (class 2606 OID 16971)
-- Name: cortes_ventas cortes_ventas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cortes_ventas
    ADD CONSTRAINT cortes_ventas_pkey PRIMARY KEY (id_corte);


--
-- TOC entry 5021 (class 2606 OID 16911)
-- Name: detalle_compras detalle_compras_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_compras
    ADD CONSTRAINT detalle_compras_pkey PRIMARY KEY (id_detalle_compra);


--
-- TOC entry 5003 (class 2606 OID 32769)
-- Name: inventario_rollos inventario_rollos_codigo_rfid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_rollos
    ADD CONSTRAINT inventario_rollos_codigo_rfid_key UNIQUE (codigo_rfid);


--
-- TOC entry 5005 (class 2606 OID 16823)
-- Name: inventario_rollos inventario_rollos_id_tela_numero_rollo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_rollos
    ADD CONSTRAINT inventario_rollos_id_tela_numero_rollo_key UNIQUE (id_tela, numero_rollo);


--
-- TOC entry 5007 (class 2606 OID 16821)
-- Name: inventario_rollos inventario_rollos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_rollos
    ADD CONSTRAINT inventario_rollos_pkey PRIMARY KEY (id_rollo);


--
-- TOC entry 5037 (class 2606 OID 24588)
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id_log);


--
-- TOC entry 5033 (class 2606 OID 17001)
-- Name: movimientos_inventario movimientos_inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_pkey PRIMARY KEY (id_movimiento);


--
-- TOC entry 4981 (class 2606 OID 16744)
-- Name: proveedores proveedores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_pkey PRIMARY KEY (id_proveedor);


--
-- TOC entry 4995 (class 2606 OID 16793)
-- Name: telas telas_codigo_tela_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telas
    ADD CONSTRAINT telas_codigo_tela_key UNIQUE (codigo_tela);


--
-- TOC entry 4997 (class 2606 OID 16791)
-- Name: telas telas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telas
    ADD CONSTRAINT telas_pkey PRIMARY KEY (id_tela);


--
-- TOC entry 4983 (class 2606 OID 16757)
-- Name: tipos_de_tela tipos_de_tela_nombre_tipo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_de_tela
    ADD CONSTRAINT tipos_de_tela_nombre_tipo_key UNIQUE (nombre_tipo);


--
-- TOC entry 4985 (class 2606 OID 16755)
-- Name: tipos_de_tela tipos_de_tela_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_de_tela
    ADD CONSTRAINT tipos_de_tela_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 5009 (class 2606 OID 16854)
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- TOC entry 5011 (class 2606 OID 16852)
-- Name: usuarios usuarios_nombre_usuario_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_nombre_usuario_key UNIQUE (nombre_usuario);


--
-- TOC entry 5013 (class 2606 OID 16850)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 5026 (class 2606 OID 16947)
-- Name: ventas ventas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_pkey PRIMARY KEY (id_venta);


--
-- TOC entry 5018 (class 1259 OID 17030)
-- Name: idx_compras_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compras_fecha ON public.compras_proveedor USING btree (fecha_compra);


--
-- TOC entry 5019 (class 1259 OID 17031)
-- Name: idx_compras_proveedor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compras_proveedor ON public.compras_proveedor USING btree (id_proveedor);


--
-- TOC entry 5034 (class 1259 OID 24594)
-- Name: idx_logs_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_logs_fecha ON public.logs USING btree (fecha DESC);


--
-- TOC entry 5035 (class 1259 OID 24595)
-- Name: idx_logs_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_logs_usuario ON public.logs USING btree (usuario_id);


--
-- TOC entry 5029 (class 1259 OID 17024)
-- Name: idx_movimientos_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_movimientos_fecha ON public.movimientos_inventario USING btree (fecha_movimiento);


--
-- TOC entry 5030 (class 1259 OID 17026)
-- Name: idx_movimientos_tela; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_movimientos_tela ON public.movimientos_inventario USING btree (id_tela);


--
-- TOC entry 5031 (class 1259 OID 17025)
-- Name: idx_movimientos_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_movimientos_tipo ON public.movimientos_inventario USING btree (tipo_movimiento);


--
-- TOC entry 4998 (class 1259 OID 17022)
-- Name: idx_rollos_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rollos_estado ON public.inventario_rollos USING btree (estado);


--
-- TOC entry 4999 (class 1259 OID 32770)
-- Name: idx_rollos_rfid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rollos_rfid ON public.inventario_rollos USING btree (codigo_rfid);


--
-- TOC entry 5000 (class 1259 OID 17021)
-- Name: idx_rollos_tela; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rollos_tela ON public.inventario_rollos USING btree (id_tela);


--
-- TOC entry 5001 (class 1259 OID 17023)
-- Name: idx_rollos_ubicacion; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rollos_ubicacion ON public.inventario_rollos USING btree (ubicacion_estante);


--
-- TOC entry 4990 (class 1259 OID 17017)
-- Name: idx_telas_codigo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_telas_codigo ON public.telas USING btree (codigo_tela);


--
-- TOC entry 4991 (class 1259 OID 17018)
-- Name: idx_telas_nombre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_telas_nombre ON public.telas USING btree (nombre_tela);


--
-- TOC entry 4992 (class 1259 OID 17019)
-- Name: idx_telas_proveedor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_telas_proveedor ON public.telas USING btree (id_proveedor);


--
-- TOC entry 4993 (class 1259 OID 17020)
-- Name: idx_telas_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_telas_tipo ON public.telas USING btree (id_tipo);


--
-- TOC entry 5022 (class 1259 OID 17029)
-- Name: idx_ventas_cliente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ventas_cliente ON public.ventas USING btree (id_cliente);


--
-- TOC entry 5023 (class 1259 OID 17027)
-- Name: idx_ventas_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ventas_fecha ON public.ventas USING btree (fecha_venta);


--
-- TOC entry 5024 (class 1259 OID 17028)
-- Name: idx_ventas_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ventas_usuario ON public.ventas USING btree (id_usuario);


--
-- TOC entry 5056 (class 2620 OID 17033)
-- Name: detalle_compras trigger_actualizar_stock_compra; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_actualizar_stock_compra AFTER INSERT ON public.detalle_compras FOR EACH ROW EXECUTE FUNCTION public.actualizar_stock_compra();


--
-- TOC entry 5058 (class 2620 OID 17035)
-- Name: cortes_ventas trigger_actualizar_stock_venta; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_actualizar_stock_venta AFTER INSERT ON public.cortes_ventas FOR EACH ROW EXECUTE FUNCTION public.actualizar_stock_venta();


--
-- TOC entry 5059 (class 2620 OID 24683)
-- Name: cortes_ventas trigger_actualizar_venta; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_actualizar_venta AFTER INSERT OR DELETE OR UPDATE ON public.cortes_ventas FOR EACH ROW EXECUTE FUNCTION public.actualizar_venta_desde_cortes();


--
-- TOC entry 5057 (class 2620 OID 24681)
-- Name: ventas trigger_calcular_total; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_calcular_total BEFORE INSERT OR UPDATE OF subtotal, descuento, iva ON public.ventas FOR EACH ROW EXECUTE FUNCTION public.actualizar_total_pagar();


--
-- TOC entry 5042 (class 2606 OID 16888)
-- Name: compras_proveedor compras_proveedor_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compras_proveedor
    ADD CONSTRAINT compras_proveedor_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES public.proveedores(id_proveedor);


--
-- TOC entry 5043 (class 2606 OID 16893)
-- Name: compras_proveedor compras_proveedor_id_usuario_registra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compras_proveedor
    ADD CONSTRAINT compras_proveedor_id_usuario_registra_fkey FOREIGN KEY (id_usuario_registra) REFERENCES public.usuarios(id_usuario);


--
-- TOC entry 5049 (class 2606 OID 16977)
-- Name: cortes_ventas cortes_ventas_id_rollo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cortes_ventas
    ADD CONSTRAINT cortes_ventas_id_rollo_fkey FOREIGN KEY (id_rollo) REFERENCES public.inventario_rollos(id_rollo);


--
-- TOC entry 5050 (class 2606 OID 16982)
-- Name: cortes_ventas cortes_ventas_id_tela_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cortes_ventas
    ADD CONSTRAINT cortes_ventas_id_tela_fkey FOREIGN KEY (id_tela) REFERENCES public.telas(id_tela);


--
-- TOC entry 5051 (class 2606 OID 16972)
-- Name: cortes_ventas cortes_ventas_id_venta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cortes_ventas
    ADD CONSTRAINT cortes_ventas_id_venta_fkey FOREIGN KEY (id_venta) REFERENCES public.ventas(id_venta) ON DELETE CASCADE;


--
-- TOC entry 5044 (class 2606 OID 16922)
-- Name: detalle_compras detalle_compras_id_color_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_compras
    ADD CONSTRAINT detalle_compras_id_color_fkey FOREIGN KEY (id_color) REFERENCES public.colores(id_color);


--
-- TOC entry 5045 (class 2606 OID 16912)
-- Name: detalle_compras detalle_compras_id_compra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_compras
    ADD CONSTRAINT detalle_compras_id_compra_fkey FOREIGN KEY (id_compra) REFERENCES public.compras_proveedor(id_compra) ON DELETE CASCADE;


--
-- TOC entry 5046 (class 2606 OID 16917)
-- Name: detalle_compras detalle_compras_id_tela_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_compras
    ADD CONSTRAINT detalle_compras_id_tela_fkey FOREIGN KEY (id_tela) REFERENCES public.telas(id_tela);


--
-- TOC entry 5040 (class 2606 OID 16829)
-- Name: inventario_rollos inventario_rollos_id_color_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_rollos
    ADD CONSTRAINT inventario_rollos_id_color_fkey FOREIGN KEY (id_color) REFERENCES public.colores(id_color);


--
-- TOC entry 5041 (class 2606 OID 16824)
-- Name: inventario_rollos inventario_rollos_id_tela_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario_rollos
    ADD CONSTRAINT inventario_rollos_id_tela_fkey FOREIGN KEY (id_tela) REFERENCES public.telas(id_tela);


--
-- TOC entry 5055 (class 2606 OID 24589)
-- Name: logs logs_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id_usuario);


--
-- TOC entry 5052 (class 2606 OID 17002)
-- Name: movimientos_inventario movimientos_inventario_id_rollo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_rollo_fkey FOREIGN KEY (id_rollo) REFERENCES public.inventario_rollos(id_rollo);


--
-- TOC entry 5053 (class 2606 OID 17007)
-- Name: movimientos_inventario movimientos_inventario_id_tela_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_tela_fkey FOREIGN KEY (id_tela) REFERENCES public.telas(id_tela);


--
-- TOC entry 5054 (class 2606 OID 17012)
-- Name: movimientos_inventario movimientos_inventario_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario);


--
-- TOC entry 5038 (class 2606 OID 16799)
-- Name: telas telas_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telas
    ADD CONSTRAINT telas_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES public.proveedores(id_proveedor);


--
-- TOC entry 5039 (class 2606 OID 16794)
-- Name: telas telas_id_tipo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telas
    ADD CONSTRAINT telas_id_tipo_fkey FOREIGN KEY (id_tipo) REFERENCES public.tipos_de_tela(id_tipo);


--
-- TOC entry 5047 (class 2606 OID 16953)
-- Name: ventas ventas_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente);


--
-- TOC entry 5048 (class 2606 OID 16948)
-- Name: ventas ventas_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario);


-- Completed on 2026-05-01 01:26:54

--
-- PostgreSQL database dump complete
--

\unrestrict xmkPz6a8vL3vRmXJ1UgKwAya37bLY4AdYyEhRbZxegSu6R1CSBpzRnVtSyLWd3n

