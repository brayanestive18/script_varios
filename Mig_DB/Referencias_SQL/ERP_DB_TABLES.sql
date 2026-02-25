create table agapes
(
    id          bigint unsigned auto_increment
        primary key,
    name        varchar(90)                             not null,
    observacion varchar(150) collate utf8mb3_spanish_ci null,
    created_at  timestamp                               null,
    updated_at  timestamp                               null,
    constraint name
        unique (name)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table careers
(
    id          bigint unsigned auto_increment
        primary key,
    name        varchar(255) not null,
    slug        varchar(255) not null,
    description text         null,
    created_at  timestamp    null,
    updated_at  timestamp    null,
    constraint careers_slug_unique
        unique (slug)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index careers_name_index
    on careers (name);

create index careers_slug_index
    on careers (slug);

create table consulta_dni_logs
(
    id                    bigint unsigned auto_increment
        primary key,
    id_responsable        int           not null,
    dni_responsable       int           not null,
    total_ids_consultados int default 0 not null,
    total_encontrados     int default 0 not null,
    total_no_encontrados  int default 0 not null,
    archivo_nombre        varchar(255)  not null,
    fecha_consulta        timestamp     not null,
    created_at            timestamp     null,
    updated_at            timestamp     null
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table est_alumno
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table est_caja
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(60) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table est_clase
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table est_cuenta
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(60) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table est_grupo
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table est_maestro
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table est_materia
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table est_matricula_materia
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table est_matricula_programa
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table est_miembro
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table est_salon
(
    id     tinyint unsigned auto_increment
        primary key,
    estado varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table failed_jobs
(
    id         bigint unsigned auto_increment
        primary key,
    uuid       varchar(255)                        not null,
    connection text                                not null,
    queue      text                                not null,
    payload    longtext                            not null,
    exception  longtext                            not null,
    failed_at  timestamp default CURRENT_TIMESTAMP not null,
    constraint failed_jobs_uuid_unique
        unique (uuid)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table formularios
(
    id        int                          not null,
    nombre    varchar(30)                  not null,
    contenido longtext collate utf8mb4_bin not null,
    check (json_valid(`contenido`))
)
    comment 'Almacena los formularios, para captura de información' engine = InnoDB
                                                                    collate = utf8mb4_unicode_ci;

create table languages
(
    id         bigint unsigned auto_increment
        primary key,
    name       varchar(255) not null,
    code       varchar(2)   not null,
    created_at timestamp    null,
    updated_at timestamp    null,
    constraint languages_code_unique
        unique (code)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table matricula_logs
(
    id                bigint unsigned auto_increment
        primary key,
    id_responsable    bigint unsigned   not null,
    dni_responsable   tinyint unsigned  not null,
    t_trans           tinyint unsigned  not null,
    sede              smallint unsigned not null,
    grupo             smallint unsigned not null,
    total_procesados  int               not null,
    total_exitosos    int               not null,
    total_fallidos    int               not null,
    alumnos_excluidos json              null,
    archivo_nombre    varchar(255)      not null,
    fecha_proceso     timestamp         not null,
    observaciones     text              null,
    created_at        timestamp         null,
    updated_at        timestamp         null
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table migrations
(
    id        int unsigned auto_increment
        primary key,
    migration varchar(255) not null,
    batch     int          not null
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table ofertas_empleo
(
    id                bigint unsigned auto_increment
        primary key,
    modalidad         enum ('VINCULADO', 'SERVICIOS', 'HIBRIDO')                                    null,
    titulo            varchar(150)                                                                  not null,
    descripcion       text                                                                          not null,
    observaciones     text                                                                          null,
    fecha_publicacion timestamp                                           default CURRENT_TIMESTAMP not null,
    fecha_cierre      timestamp                                                                     null,
    estado            enum ('ACTIVA', 'PAUSADA', 'CUBIERTA', 'CANCELADA') default 'ACTIVA'          not null,
    created_at        timestamp                                                                     null,
    updated_at        timestamp                                                                     null
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table pais
(
    id     mediumint unsigned not null
        primary key,
    nombre varchar(60)        not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table banco
(
    id      smallint unsigned auto_increment
        primary key,
    nombre  varchar(60)                  not null,
    pais    mediumint unsigned           not null,
    vigente tinyint unsigned default '1' not null,
    constraint banco_f1
        foreign key (pais) references pais (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table password_reset_tokens
(
    email      varchar(255) not null
        primary key,
    token      varchar(255) not null,
    created_at timestamp    null
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table permissions
(
    id         bigint unsigned auto_increment
        primary key,
    name       varchar(255) not null,
    guard_name varchar(255) not null,
    created_at timestamp    null,
    updated_at timestamp    null,
    constraint permissions_name_guard_name_unique
        unique (name, guard_name)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table model_has_permissions
(
    permission_id bigint unsigned not null,
    model_type    varchar(255)    not null,
    model_id      bigint unsigned not null,
    team_id       bigint unsigned not null,
    primary key (team_id, permission_id, model_id, model_type),
    constraint model_has_permissions_permission_id_foreign
        foreign key (permission_id) references permissions (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index model_has_permissions_model_id_model_type_index
    on model_has_permissions (model_id, model_type);

create index model_has_permissions_team_foreign_key_index
    on model_has_permissions (team_id);

create table personal_access_tokens
(
    id             bigint unsigned auto_increment
        primary key,
    tokenable_type varchar(255)    not null,
    tokenable_id   bigint unsigned not null,
    name           varchar(255)    not null,
    token          varchar(64)     not null,
    abilities      text            null,
    last_used_at   timestamp       null,
    expires_at     timestamp       null,
    created_at     timestamp       null,
    updated_at     timestamp       null,
    constraint personal_access_tokens_token_unique
        unique (token)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index personal_access_tokens_tokenable_type_tokenable_id_index
    on personal_access_tokens (tokenable_type, tokenable_id);

create table provincia
(
    id     smallint unsigned  not null
        primary key,
    nombre varchar(60)        not null,
    pais   mediumint unsigned not null,
    constraint provincia_1
        foreign key (pais) references pais (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table roles
(
    id         bigint unsigned auto_increment
        primary key,
    team_id    bigint unsigned null,
    name       varchar(255)    not null,
    guard_name varchar(255)    not null,
    created_at timestamp       null,
    updated_at timestamp       null,
    constraint roles_team_id_name_guard_name_unique
        unique (team_id, name, guard_name)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table model_has_roles
(
    role_id    bigint unsigned not null,
    model_type varchar(255)    not null,
    model_id   bigint unsigned not null,
    team_id    bigint unsigned not null,
    primary key (team_id, role_id, model_id, model_type),
    constraint model_has_roles_role_id_foreign
        foreign key (role_id) references roles (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index model_has_roles_model_id_model_type_index
    on model_has_roles (model_id, model_type);

create index model_has_roles_team_foreign_key_index
    on model_has_roles (team_id);

create table role_has_permissions
(
    permission_id bigint unsigned not null,
    role_id       bigint unsigned not null,
    primary key (permission_id, role_id),
    constraint role_has_permissions_permission_id_foreign
        foreign key (permission_id) references permissions (id)
            on delete cascade,
    constraint role_has_permissions_role_id_foreign
        foreign key (role_id) references roles (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index roles_team_foreign_key_index
    on roles (team_id);

create table sede
(
    id                smallint unsigned auto_increment
        primary key,
    nombre            varchar(40)        not null,
    prefijo_trans     char(4)            not null,
    pais              mediumint unsigned not null,
    provincia         smallint unsigned  not null,
    ciudad            varchar(50)        null,
    direccion         varchar(80)        not null,
    barrio            varchar(40)        not null,
    telefono          varchar(40)        null,
    email             varchar(50)        null,
    res_factura       bigint unsigned    null,
    fecha_res_factura date               null,
    res_num_inicio    bigint unsigned    null,
    res_num_fin       bigint unsigned    null,
    vigente           tinyint unsigned   not null,
    fecha_trans       datetime           not null,
    id_responsable    bigint unsigned    not null,
    dni_responsable   tinyint unsigned   not null,
    constraint prefijo_trans
        unique (prefijo_trans),
    constraint sede_1
        foreign key (pais) references pais (id)
            on update cascade on delete cascade,
    constraint sede_2
        foreign key (provincia) references provincia (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table sequences
(
    nombre varchar(30) not null comment 'Nombre de la secuencia'
        primary key,
    valor  bigint      not null comment 'Valor actual de la secuencia',
    constraint SEQ_VALOR_UK
        unique (valor)
)
    comment 'Almacena las secuencias' engine = InnoDB
                                      collate = utf8mb4_unicode_ci;

create table t_car_discapacidad
(
    id      bigint unsigned auto_increment
        primary key,
    tipo    varchar(60)                  not null,
    vigente tinyint unsigned default '1' not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_car_grupo_especial
(
    id      bigint unsigned auto_increment
        primary key,
    tipo    varchar(60)                  not null,
    vigente tinyint unsigned default '1' not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_cuenta
(
    id      tinyint unsigned auto_increment
        primary key,
    tipo    varchar(60)                  not null,
    vigente tinyint unsigned default '1' not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_curso
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(60) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_dni
(
    id          tinyint unsigned auto_increment
        primary key,
    tipo        varchar(40) not null,
    abreviacion varchar(10) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_est_civil
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_estudio
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(60) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_evento
(
    id      tinyint unsigned             not null
        primary key,
    tipo    varchar(40)                  not null,
    vigente tinyint unsigned default '1' not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_formacion
(
    id          tinyint unsigned auto_increment
        primary key,
    tipo        varchar(60)  not null,
    descripcion varchar(255) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_grupo
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(60) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_maestro
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_material
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_medio_pago
(
    id       tinyint unsigned auto_increment
        primary key,
    tipo     varchar(60)                  not null,
    efectivo tinyint unsigned             not null,
    banco    tinyint unsigned             not null,
    vigente  tinyint unsigned default '1' not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_ocupacion
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_perfil
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_publicidad
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_reporte
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(40) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_trans
(
    id              tinyint unsigned auto_increment
        primary key,
    tipo            varchar(60)      not null,
    controlador     varchar(30)      not null,
    dinero          tinyint unsigned not null,
    cuenta_x_cobrar tinyint unsigned not null,
    cuenta_x_pagar  tinyint unsigned not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table t_usuario
(
    id   tinyint unsigned auto_increment
        primary key,
    tipo varchar(60) not null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table task_types
(
    id          bigint unsigned auto_increment
        primary key,
    name        varchar(100)                 not null comment 'Nombre del tipo de tarea',
    description text                         null comment 'Descripción detallada de la tarea',
    active      tinyint unsigned default '1' not null comment 'Indica si el tipo de tarea está activo',
    created_at  timestamp                    null,
    updated_at  timestamp                    null,
    constraint task_types_name_unique
        unique (name)
)
    comment 'Catálogo de tipos de tareas: entrevista caracterización, llamada acompañamiento, etc.' engine = InnoDB
                                                                                                    collate = utf8mb4_unicode_ci;

create table teams
(
    id         bigint unsigned auto_increment
        primary key,
    name       varchar(255) not null,
    created_at timestamp    null,
    updated_at timestamp    null
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table transaccion
(
    t_trans  tinyint unsigned             not null,
    sede     smallint unsigned            not null,
    id_trans bigint unsigned              not null,
    vigente  tinyint unsigned default '1' not null,
    primary key (t_trans, sede, id_trans),
    constraint transaccion_1
        foreign key (t_trans) references t_trans (id)
            on update cascade on delete cascade,
    constraint transaccion_2
        foreign key (sede) references sede (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table users
(
    id                bigint unsigned auto_increment
        primary key,
    name              varchar(255)                         not null,
    role_id           enum ('1', '2', '3', '') default '1' not null,
    email             varchar(255)                         not null,
    email_verified_at timestamp                            null,
    password          varchar(255)                         not null,
    remember_token    varchar(100)                         null,
    created_at        timestamp                            null,
    updated_at        timestamp                            null,
    prueba            longtext collate utf8mb4_bin         null,
    constraint users_email_unique
        unique (email),
    check (json_valid(`prueba`))
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci;

create table usuario
(
    id                                       bigint unsigned              not null,
    dni                                      tinyint unsigned             not null,
    perfil                                   tinyint unsigned             not null,
    password1                                varchar(255)                 null,
    email_verified_at                        varchar(255)                 null,
    password                                 varchar(255)                 null,
    remember_token                           varchar(100)                 null,
    created_at                               timestamp                    null,
    updated_at                               timestamp                    null,
    nombre1                                  varchar(30)                  not null,
    nombre2                                  varchar(30)                  null,
    apellido1                                varchar(30)                  not null,
    apellido2                                varchar(30)                  null,
    pais_nacimiento                          mediumint unsigned           null,
    fecha_nacimiento                         date                         null,
    genero                                   char                         not null,
    est_civil                                tinyint unsigned             null,
    cant_hijos                               tinyint unsigned             null,
    pais                                     mediumint unsigned           null,
    provincia                                smallint unsigned            null,
    ciudad                                   varchar(50)                  null,
    direccion                                varchar(80)                  null,
    barrio                                   varchar(40)                  null,
    telefono                                 varchar(40)                  null,
    celular                                  varchar(10)                  null,
    email                                    varchar(80)                  null,
    sede_ppal                                smallint unsigned            not null,
    servidor_covid                           tinyint unsigned default '0' not null,
    vigente                                  tinyint unsigned default '0' not null,
    fecha_ingreso                            date                         null,
    ocupacion                                tinyint unsigned             null,
    empresa                                  varchar(40)                  null,
    telefono_empresa                         varchar(40)                  null,
    fecha_ingreso_empresa                    date                         null,
    eps                                      varchar(40)                  null,
    t_publicidad                             tinyint unsigned             null,
    fecha_trans                              datetime                     not null,
    id_responsable                           bigint unsigned              not null,
    dni_responsable                          tinyint unsigned             not null,
    fecha_inicio_servicio                    date                         null,
    t_registro                               tinyint unsigned default '1' not null,
    password_old                             varchar(255)                 null,
    imagen                                   varchar(120)                 null,
    nivel_escolaridad                        tinyint                      null,
    servicio_comunidad_catolica              varchar(80)                  null,
    fecha_inicio_servicio_comunidad_catolica date                         null,
    primary key (id, dni),
    constraint usuario_10
        foreign key (t_publicidad) references t_publicidad (id)
            on update cascade on delete cascade,
    constraint usuario_11
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint usuario_2
        foreign key (dni) references t_dni (id)
            on update cascade on delete cascade,
    constraint usuario_3
        foreign key (perfil) references t_perfil (id)
            on update cascade on delete cascade,
    constraint usuario_4
        foreign key (pais_nacimiento) references pais (id)
            on update cascade on delete cascade,
    constraint usuario_5
        foreign key (est_civil) references t_est_civil (id)
            on update cascade on delete cascade,
    constraint usuario_6
        foreign key (pais) references pais (id)
            on update cascade on delete cascade,
    constraint usuario_7
        foreign key (provincia) references provincia (id)
            on update cascade on delete cascade,
    constraint usuario_8
        foreign key (sede_ppal) references sede (id)
            on update cascade on delete cascade,
    constraint usuario_9
        foreign key (ocupacion) references t_ocupacion (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table alumno
(
    id              bigint unsigned  not null,
    dni             tinyint unsigned not null,
    est_alumno      tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    primary key (id, dni),
    constraint alumno_1
        foreign key (id, dni) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint alumno_2
        foreign key (dni) references t_dni (id)
            on update cascade on delete cascade,
    constraint alumno_3
        foreign key (est_alumno) references est_alumno (id)
            on update cascade on delete cascade,
    constraint alumno_4
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table caja
(
    sede                      smallint unsigned            not null,
    id                        mediumint unsigned           not null,
    nombre                    varchar(60)                  not null,
    id_cajero                 bigint unsigned              null,
    dni_cajero                tinyint unsigned             null,
    est_caja                  tinyint unsigned             not null,
    vigente                   tinyint unsigned default '1' not null,
    fecha_trans               datetime                     not null,
    id_responsable            bigint unsigned              null,
    dni_responsable           tinyint unsigned             null,
    fecha_modificar           datetime                     null,
    id_responsable_modificar  bigint unsigned              null,
    dni_responsable_modificar tinyint unsigned             null,
    fecha_anular              datetime                     null,
    observacion_anular        varchar(255)                 null,
    id_responsable_anular     bigint unsigned              null,
    dni_responsable_anular    tinyint unsigned             null,
    fecha_autorizar           datetime                     null,
    id_responsable_autorizar  bigint unsigned              null,
    dni_responsable_autorizar tinyint unsigned             null,
    primary key (sede, id),
    constraint caja_1
        foreign key (sede) references sede (id)
            on update cascade on delete cascade,
    constraint caja_2
        foreign key (id_cajero, dni_cajero) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint caja_3
        foreign key (est_caja) references est_caja (id)
            on update cascade on delete cascade,
    constraint caja_4
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint caja_5
        foreign key (id_responsable_modificar, dni_responsable_modificar) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint caja_6
        foreign key (id_responsable_anular, dni_responsable_anular) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint caja_7
        foreign key (id_responsable_autorizar, dni_responsable_autorizar) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create index caja_i1
    on caja (nombre);

create table car_agapes_preferences
(
    id                          bigint unsigned auto_increment
        primary key,
    cercania_amigo_estudio      tinyint unsigned default '0' not null comment 'Si ¿Estás haciendo el proceso de quintos convocados con algún familiar yamigo cercano?',
    nombre_amigo                varchar(200)                 null comment 'describir nombre y cedula del amigo',
    grados_instituto            tinyint unsigned default '0' not null comment 'Si no condiciona',
    fecha_grados                varchar(100)                 null comment 'Con tambien puede ser otra ocupacion',
    lugar_residencia            tinyint unsigned default '0' not null comment 'Si no condiciona',
    detalle_problema_residencia varchar(100)                 null comment 'Impedimiento futuro',
    tratamiento_psiquico        tinyint unsigned default '0' not null comment 'Si no condiciona',
    tipo_tratamiento            varchar(100)     default '0' not null comment 'Escribir el tratamiento',
    medicamento_consume         tinyint unsigned default '0' not null comment 'Si no condiciona',
    tipo_medicamento            varchar(100)     default '0' not null comment 'Escribir el tratamiento',
    id_responsable              bigint unsigned              null,
    dni_responsable             tinyint unsigned             null,
    created_at                  timestamp                    null,
    updated_at                  timestamp                    null,
    constraint car_agapes_preferences
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table car_socio_agapes_usuarios
(
    id              bigint unsigned  not null comment 'Identificador del enganche conocimiento usuarios agapes',
    id_usuario      bigint unsigned  not null comment 'Número de identificación del usuario inscrito al evento, relacionado con la estructura usuario campo id',
    dni_usuario     tinyint unsigned not null comment 'Tipo de identificación del usuario inscrito al evento. 1-Cedula de ciudadanía',
    id_responsable  bigint unsigned  null comment 'Identificación de la persona responsable del evento',
    dni_responsable tinyint unsigned null comment 'Tipo de identificación de la persona responsable del evento',
    fecha_novedad   timestamp        null comment 'Fecha y hora de actualizacion',
    primary key (id, id_usuario, dni_usuario),
    constraint car_socio_agapes_usuarios1
        foreign key (id) references car_agapes_preferences (id)
            on update cascade on delete cascade,
    constraint car_socio_agapes_usuarios2
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint car_socio_agapes_usuarios3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table car_socio_epsp
(
    id                   bigint unsigned auto_increment
        primary key,
    id_usuario           bigint unsigned                                                                                                                                         not null,
    est_civil            tinyint unsigned                                                                                                                                        null comment 'Referencia a t_est_civil',
    tiene_pareja         tinyint(1)                                                                                                                                              null comment '1=Sí, 0=No, NULL=No aplica',
    nombre_pareja        varchar(50)                                                                                                                                             null,
    tipo_vivienda        enum ('PROPIA', 'FAMILIAR', 'ARRENDADA')                                                                                                                not null,
    medio_transporte     enum ('METRO Y PUBLICO', 'PUBLICO', 'VEHICULO PROPIO', 'MOTO PROPIA')                                                                                   not null,
    salud_prepagada      tinyint unsigned default '0'                                                                                                                            not null,
    discapacidad         tinyint unsigned default '0'                                                                                                                            not null comment 'En caso de ser 1 se debe asociar a al tabla dispapacidades',
    eps                  varchar(150)                                                                                                                                            not null,
    tipo_sangre          enum ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')                                                                                                 not null,
    grupo_especial       tinyint unsigned default '0'                                                                                                                            not null comment 'pertenece a un grupo especial como: Pensionado, Desplazado, Inmigrante (Puede seleccionar varios) tabla grupo_especial',
    emfermedades         varchar(200)                                                                                                                                            not null comment 'Relacion de emfermedades de base',
    situacion_economica  enum ('DESEMPLEADO NO BUSCA EMPLEO', 'DESEMPLEADO BUSCA EMPLEO', 'INDEPENDIENTE', 'INDEPENDIENTE BUSCA EMPLEO', 'EMPLEADO', 'EMPRESARIO', 'PENSIONADO') not null,
    genera_empleo        tinyint          default 0                                                                                                                              not null,
    accidentes           varchar(200)                                                                                                                                            null comment 'Relacion de accidentes importantes',
    tiene_emprendimiento tinyint          default 0                                                                                                                              not null,
    tipo_emprendimiento  varchar(300)                                                                                                                                            null,
    id_responsable       bigint unsigned                                                                                                                                         null,
    created_at           timestamp                                                                                                                                               null,
    updated_at           timestamp                                                                                                                                               null,
    constraint car_socio_epsp_id_usuario_unique
        unique (id_usuario),
    constraint car_socio_epsp_id_responsable_foreign
        foreign key (id_responsable) references usuario (id)
            on update cascade on delete set null,
    constraint car_socio_epsp_id_usuario_foreign
        foreign key (id_usuario) references usuario (id)
            on update cascade on delete cascade,
    constraint fk_car_socio_epsp_est_civil
        foreign key (est_civil) references t_est_civil (id)
            on update cascade on delete set null
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table academic_profiles
(
    id                  bigint unsigned auto_increment
        primary key,
    car_socio_epsp_id   bigint unsigned                                                                                                                                              not null,
    highest_degree      enum ('ninguno', 'primaria', 'bachiller', 'tecnico', 'tecnologo', 'pregrado', 'especializacion', 'maestria', 'doctorado', 'postdoctorado') default 'ninguno' not null,
    is_current_student  tinyint(1)                                                                                                                                 default 0         not null,
    current_study_level enum ('iniciando', 'mitad', 'finalizando')                                                                                                                   null,
    is_autodidact       tinyint(1)                                                                                                                                 default 0         not null,
    has_skill           tinyint(1)                                                                                                                                 default 0         not null,
    years_of_experience int                                                                                                                                        default 0         not null,
    skills              varchar(300)                                                                                                                                                 null,
    created_at          timestamp                                                                                                                                                    null,
    updated_at          timestamp                                                                                                                                                    null,
    constraint academic_profiles_car_socio_epsp_id_foreign
        foreign key (car_socio_epsp_id) references car_socio_epsp (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table academic_profile_career
(
    id                  bigint unsigned auto_increment
        primary key,
    academic_profile_id bigint unsigned                                                                not null,
    career_id           bigint unsigned                                                                not null,
    status              enum ('estudiante', 'graduado', 'ejerciente', 'inactivo') default 'estudiante' not null,
    progress            enum ('iniciando', 'mitad', 'finalizando')                                     null,
    is_main             tinyint(1)                                                default 0            not null,
    created_at          timestamp                                                                      null,
    updated_at          timestamp                                                                      null,
    constraint academic_profile_career_unique
        unique (academic_profile_id, career_id),
    constraint academic_profile_career_academic_profile_id_foreign
        foreign key (academic_profile_id) references academic_profiles (id)
            on delete cascade,
    constraint academic_profile_career_career_id_foreign
        foreign key (career_id) references careers (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table academic_profile_language
(
    id                  bigint unsigned auto_increment
        primary key,
    academic_profile_id bigint unsigned                                                      not null,
    language_id         bigint unsigned                                                      not null,
    reading_level       enum ('basico', 'intermedio', 'avanzado', 'nativo') default 'basico' not null,
    writing_level       enum ('basico', 'intermedio', 'avanzado', 'nativo') default 'basico' not null,
    speaking_level      enum ('basico', 'intermedio', 'avanzado', 'nativo') default 'basico' not null,
    created_at          timestamp                                                            null,
    updated_at          timestamp                                                            null,
    constraint academic_profile_language_unique
        unique (academic_profile_id, language_id),
    constraint academic_profile_language_academic_profile_id_foreign
        foreign key (academic_profile_id) references academic_profiles (id)
            on delete cascade,
    constraint academic_profile_language_language_id_foreign
        foreign key (language_id) references languages (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table car_area_personal
(
    id                      bigint unsigned auto_increment
        primary key,
    car_socio_epsp_id       bigint unsigned  not null,
    proyecto_vida           varchar(600)     not null comment 'Cual es tu proyecto de vida',
    proyecto_vida_familiar  varchar(600)     not null comment 'Cual es tu proyecto de vida Qué proyecto tienes con tu familia',
    suenos_aspiraciones     varchar(600)     not null comment 'Describe tus sueños y aspiraciones',
    fortalezas              varchar(600)     not null comment 'Describe tus fortalezas',
    oportunidades_de_mejora varchar(600)     not null comment 'Describe tus oportunidades de mejora',
    id_responsable          bigint unsigned  null,
    dni_responsable         tinyint unsigned null,
    created_at              timestamp        null,
    updated_at              timestamp        null,
    constraint car_area_personal_1
        foreign key (car_socio_epsp_id) references car_socio_epsp (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table car_experiencia_laboral
(
    id                bigint unsigned auto_increment
        primary key,
    car_socio_epsp_id bigint unsigned not null,
    nombre            varchar(80)     not null comment 'Empresa en la que labora o laboro',
    cargo             varchar(80)     not null comment 'Cargo en la empresa en la que labora o laboro',
    tiempo_laborado   varchar(80)     not null comment 'Tiempo laborado',
    motivo_retiro     varchar(80)     null comment 'Motivo de retiro de la empresa',
    observaciones     varchar(80)     null comment 'Observaciones',
    created_at        timestamp       null,
    updated_at        timestamp       null,
    constraint car_experiencia_laboral
        foreign key (car_socio_epsp_id) references car_socio_epsp (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table car_grupo_familiar
(
    id                    bigint unsigned auto_increment
        primary key,
    car_socio_epsp_id     bigint unsigned      not null,
    nombre                varchar(80)          not null,
    parentesco            varchar(80)          not null,
    ocupacion             varchar(80)          not null,
    edad                  varchar(1020)        null,
    aporta_economicamente tinyint(1) default 0 not null,
    created_at            timestamp            null,
    updated_at            timestamp            null,
    constraint car_socio_epsp_1
        foreign key (car_socio_epsp_id) references car_socio_epsp (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table car_ministerio_comunidad
(
    id                                    bigint unsigned auto_increment
        primary key,
    car_socio_epsp_id                     bigint unsigned              not null,
    es_servidor                           tinyint unsigned default '0' not null comment 'Si no condiciona presta algun servicio en la comunidad',
    es_servidor_fecha                     timestamp                    null,
    es_servidor_servicio_prestado         varchar(100)                 not null comment 'Que servicio presta',
    lider_inmediato                       varchar(100)                 not null comment 'deberia llamar a los lideres actuales',
    servicio_comunidad_catolica           tinyint unsigned default '0' not null comment 'Si no condiciona',
    servicio_comunidad_catolica_parr_serv varchar(200)                 not null comment 'describir parroquia servicio y tiempode servicio',
    cercania_sacerdote                    tinyint unsigned default '0' not null comment 'Si no condiciona',
    cercania_sacerdote_detalle            varchar(100)                 not null comment 'Con quien y que tipo de relacion',
    cercania_pastor                       tinyint unsigned default '0' not null comment 'Si no condiciona',
    cercania_pastor_detalle               varchar(100)                 not null comment 'Con quien y que tipo de relacion',
    prueba_espiritual                     tinyint unsigned default '0' not null comment 'Si no condiciona',
    prueba_espiritual_resultado           tinyint unsigned default '0' not null comment 'Si no condiciona positivo negativo',
    prueba_espiritual_apoyo               tinyint unsigned default '0' not null comment 'Necesidad de acompañamiento',
    pastoral_estado_proceso               tinyint unsigned default '0' not null comment 'En proceso o finalizado',
    prueba_espiritual_proceso             varchar(100)                 not null comment 'Esta en tratamiento u observaciones',
    plan_salvacion                        varchar(100)                 not null comment 'Describe en dos frases lo que entienes por plan de salvacion',
    relevante_proceso_comunidad           varchar(200)                 not null comment 'Durante el proceso que has llevado en la comunidad, qué ha sido lo mas edificante o relevante para ti',
    satisfacion_proceso_comunidad         varchar(200)                 not null comment '¿Qué tan satisfecho te sientes con la formación y el acompañamiento de la comunidad?',
    mejora_comunidad                      varchar(200)                 not null comment '¿En qué aspectos consideras que debemos mejorar?',
    id_responsable                        bigint unsigned              null,
    dni_responsable                       tinyint unsigned             null,
    created_at                            timestamp                    null,
    updated_at                            timestamp                    null,
    constraint car_relacion_comunidad
        foreign key (car_socio_epsp_id) references car_socio_epsp (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table car_relacion_comunidad
(
    id                                            bigint unsigned auto_increment
        primary key,
    car_socio_epsp_id                             bigint unsigned                                            not null,
    i_denominacional                              enum ('CATOLICO', 'EVANGELICO', 'OTRO') default 'CATOLICO' not null,
    es_diezmador                                  tinyint unsigned                        default '0'        not null comment 'Si no condiciona',
    es_diezmador_response                         varchar(100)                                               null comment 'Que te impide diezmar',
    servicio_comunidad_catolica                   tinyint unsigned                        default '0'        not null comment 'Si no condiciona',
    servicio_comunidad_catolica_parroquia_realiza varchar(200)                                               null comment 'describir parroquia servicio y tiempode servicio',
    cercania_sacerdote                            tinyint unsigned                        default '0'        not null comment 'Si no condiciona',
    cercania_sacerdote_detalle                    varchar(100)                                               null comment 'Con quien y que tipo de relacion',
    cercania_pastor                               tinyint unsigned                        default '0'        not null comment 'Si no condiciona',
    cercania_pastor_detalle                       varchar(100)                                               null comment 'Con quien y que tipo de relacion',
    prueba_espiritual                             tinyint unsigned                        default '0'        not null comment 'Si no condiciona',
    prueba_espiritual_fecha                       timestamp                                                  null,
    prueba_espiritual_resultado                   varchar(200)                            default '0'        not null comment 'Escribir el resultado de la prueba espiritual',
    pastoral_inicio_atencion                      tinyint unsigned                        default '0'        not null comment 'Acompañamiento en atencion pastoral',
    pastoral_estado_proceso                       enum ('NULL', 'EN PROCESO', 'FINALIZADO', 'DETENIDO')      null comment 'Esta en tratamiento u observaciones',
    plan_salvacion                                varchar(200)                                               not null comment 'Describe en dos frases lo que entienes por plan de salvacion',
    estudios_otras_comunidades                    tinyint                                 default 0          not null,
    relevante_proceso_comunidad                   varchar(200)                                               not null comment 'Durante el proceso que has llevado en la comunidad, qué ha sido lo mas edificante o relevante para ti',
    satisfacion_proceso_comunidad                 varchar(200)                                               not null comment '¿Qué tan satisfecho te sientes con la formación y el acompañamiento de la comunidad?',
    mejora_comunidad                              varchar(200)                                               not null comment '¿En qué aspectos consideras que debemos mejorar?',
    servidores_pastoral_atencion                  varchar(200)                                               null comment 'Relacion de servidores que han atendido el proceso en pastoral',
    procesos_pastoral_stop_razones                varchar(200)                                               null comment 'Razones por las que se ha detenido el proceso en pastoral',
    pregunta_plan_salvacion                       tinyint unsigned                        default '0'        not null comment 'Pregunta si el usuario esta seguro de su salvacion, si no condiciona',
    id_responsable                                bigint unsigned                                            null,
    dni_responsable                               tinyint unsigned                                           null,
    created_at                                    timestamp                                                  null,
    updated_at                                    timestamp                                                  null,
    constraint car_relacion_comunidad1
        foreign key (car_socio_epsp_id) references car_socio_epsp (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create index car_relacion_comunidad
    on car_relacion_comunidad (car_socio_epsp_id);

create index car_socio_epsp_id_responsable
    on car_socio_epsp (id_responsable);

create table consentimientos
(
    id                   bigint unsigned auto_increment
        primary key,
    id_usuario           bigint unsigned   not null,
    texto_consentimiento text              null,
    aceptado             tinyint default 0 not null,
    fecha_aceptacion     timestamp         null,
    ip_aceptacion        varchar(45)       null,
    created_at           timestamp         null,
    updated_at           timestamp         null,
    constraint consentimientos_id_usuario_unique
        unique (id_usuario),
    constraint consentimientos_id_usuario_foreign
        foreign key (id_usuario) references usuario (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table consultores_pastorales
(
    id           bigint unsigned auto_increment
        primary key,
    usuario_id   bigint unsigned      not null,
    especialidad text                 null,
    activo       tinyint(1) default 1 not null,
    created_at   timestamp            null,
    updated_at   timestamp            null,
    constraint consultores_pastorales_usuario_id_foreign
        foreign key (usuario_id) references usuario (id)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table cuenta
(
    id                        mediumint unsigned auto_increment
        primary key,
    nombre                    varchar(60)                  not null,
    banco                     smallint unsigned            not null,
    t_cuenta                  tinyint unsigned             not null,
    numero                    varchar(20)                  not null,
    est_cuenta                tinyint unsigned             not null,
    vigente                   tinyint unsigned default '1' not null,
    fecha_trans               datetime                     not null,
    id_responsable            bigint unsigned              null,
    dni_responsable           tinyint unsigned             null,
    fecha_modificar           datetime                     null,
    id_responsable_modificar  bigint unsigned              null,
    dni_responsable_modificar tinyint unsigned             null,
    fecha_anular              datetime                     null,
    observacion_anular        varchar(255)                 null,
    id_responsable_anular     bigint unsigned              null,
    dni_responsable_anular    tinyint unsigned             null,
    fecha_autorizar           datetime                     null,
    id_responsable_autorizar  bigint unsigned              null,
    dni_responsable_autorizar tinyint unsigned             null,
    constraint cuenta_1
        foreign key (t_cuenta) references t_cuenta (id)
            on update cascade on delete cascade,
    constraint cuenta_2
        foreign key (banco) references banco (id)
            on update cascade on delete cascade,
    constraint cuenta_3
        foreign key (est_cuenta) references est_cuenta (id)
            on update cascade on delete cascade,
    constraint cuenta_4
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint cuenta_5
        foreign key (id_responsable_modificar, dni_responsable_modificar) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint cuenta_6
        foreign key (id_responsable_anular, dni_responsable_anular) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint cuenta_7
        foreign key (id_responsable_autorizar, dni_responsable_autorizar) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create index cuenta_i1
    on cuenta (nombre);

create table cuenta_x_caja
(
    cuenta          mediumint unsigned           not null,
    sede            smallint unsigned            not null,
    caja            mediumint unsigned           not null,
    ingresar        tinyint unsigned             not null,
    retirar         tinyint unsigned             not null,
    consultar       tinyint unsigned             not null,
    vigente         tinyint unsigned default '1' not null,
    fecha_trans     datetime                     not null,
    id_responsable  bigint unsigned              null,
    dni_responsable tinyint unsigned             null,
    primary key (cuenta, sede, caja),
    constraint cuenta_x_caja_1
        foreign key (cuenta) references cuenta (id)
            on update cascade on delete cascade,
    constraint cuenta_x_caja_2
        foreign key (sede) references sede (id)
            on update cascade on delete cascade,
    constraint cuenta_x_caja_3
        foreign key (sede, caja) references caja (sede, id)
            on update cascade on delete cascade,
    constraint cuenta_x_caja_4
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table curso_x_usuario
(
    t_curso     tinyint unsigned not null,
    id_usuario  bigint unsigned  not null,
    dni_usuario tinyint unsigned not null,
    vigente     tinyint unsigned not null,
    primary key (t_curso, id_usuario, dni_usuario),
    constraint curso_x_usuario_1
        foreign key (t_curso) references t_curso (id)
            on update cascade on delete cascade,
    constraint curso_x_usuario_2
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table anular_curso_x_usuario
(
    id              bigint unsigned auto_increment
        primary key,
    t_curso         tinyint unsigned not null,
    id_usuario      bigint unsigned  not null,
    dni_usuario     tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    constraint anular_curso_x_usuario_1
        foreign key (t_curso, id_usuario, dni_usuario) references curso_x_usuario (t_curso, id_usuario, dni_usuario)
            on update cascade on delete cascade,
    constraint anular_curso_x_usuario_2
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table asignar_curso_x_usuario
(
    id              bigint unsigned auto_increment
        primary key,
    t_curso         tinyint unsigned not null,
    id_usuario      bigint unsigned  not null,
    dni_usuario     tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    constraint asignar_curso_x_usuario_1
        foreign key (t_curso, id_usuario, dni_usuario) references curso_x_usuario (t_curso, id_usuario, dni_usuario)
            on update cascade on delete cascade,
    constraint asignar_curso_x_usuario_2
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table discapacidad_epsp
(
    discapacidad_id bigint unsigned not null,
    epsp_id         bigint unsigned not null,
    created_at      timestamp       not null,
    updated_at      timestamp       not null,
    primary key (discapacidad_id, epsp_id),
    constraint discapacidad_epsp_1
        foreign key (discapacidad_id) references t_car_discapacidad (id)
            on update cascade on delete cascade,
    constraint discapacidad_epsp_2
        foreign key (epsp_id) references car_socio_epsp (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index discapacidad_id
    on discapacidad_epsp (discapacidad_id);

create index epsp_id
    on discapacidad_epsp (epsp_id);

create table estudio_x_usuario
(
    id              bigint unsigned auto_increment
        primary key,
    t_estudio       tinyint unsigned not null,
    id_usuario      bigint unsigned  not null,
    dni_usuario     tinyint unsigned not null,
    estudio         varchar(120)     not null,
    nivel_alcanzado varchar(120)     not null,
    comunidad       varchar(120)     not null,
    vigente         tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    constraint estudio_x_usuario_1
        foreign key (t_estudio) references t_estudio (id)
            on update cascade on delete cascade,
    constraint estudio_x_usuario_2
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint estudio_x_usuario_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table evento
(
    id              bigint unsigned auto_increment
        primary key,
    sede            smallint unsigned                    not null,
    t_evento        tinyint unsigned                     not null,
    nombre          varchar(120)                         not null,
    url_imagen      varchar(255)                         null,
    lugar           varchar(60)                          not null,
    fecha_inicio    datetime                             not null,
    fecha_fin       datetime                             not null,
    donacion        decimal(14, 2) unsigned default 0.00 not null,
    capacidad       int unsigned            default '0'  not null,
    registro        tinyint unsigned        default '0'  not null,
    visible_publico tinyint unsigned        default '1'  not null,
    descripcion     varchar(1023)                        not null,
    fecha_trans     datetime                             not null,
    id_responsable  bigint unsigned                      not null,
    dni_responsable tinyint unsigned                     not null,
    vigente         tinyint unsigned        default '1'  not null,
    constraint evento_1
        foreign key (t_evento) references t_evento (id)
            on update cascade on delete cascade,
    constraint evento_2
        foreign key (sede) references sede (id)
            on update cascade on delete cascade,
    constraint evento_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table asistencia_evento
(
    evento          bigint unsigned              not null,
    id_usuario      bigint unsigned              not null,
    dni_usuario     tinyint unsigned             not null,
    vigente         tinyint unsigned default '1' not null,
    fecha_trans     datetime                     not null,
    id_responsable  bigint unsigned              not null,
    dni_responsable tinyint unsigned             not null,
    primary key (evento, id_usuario, dni_usuario),
    constraint asistencia_evento_1
        foreign key (evento) references evento (id)
            on update cascade on delete cascade,
    constraint asistencia_evento_2
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint asistencia_evento_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table formacion_x_usuario
(
    t_formacion tinyint unsigned not null,
    id_usuario  bigint unsigned  not null,
    dni_usuario tinyint unsigned not null,
    vigente     tinyint unsigned not null,
    primary key (t_formacion, id_usuario, dni_usuario),
    constraint formacion_x_usuario_1
        foreign key (t_formacion) references t_formacion (id)
            on update cascade on delete cascade,
    constraint formacion_x_usuario_2
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table anular_formacion_x_usuario
(
    id              bigint unsigned auto_increment
        primary key,
    t_formacion     tinyint unsigned not null,
    id_usuario      bigint unsigned  not null,
    dni_usuario     tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    constraint anular_formacion_x_usuario_1
        foreign key (t_formacion, id_usuario, dni_usuario) references formacion_x_usuario (t_formacion, id_usuario, dni_usuario)
            on update cascade on delete cascade,
    constraint anular_formacion_x_usuario_2
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table asignar_formacion_x_usuario
(
    id              bigint unsigned auto_increment
        primary key,
    t_formacion     tinyint unsigned not null,
    id_usuario      bigint unsigned  not null,
    dni_usuario     tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    constraint asignar_formacion_x_usuario_1
        foreign key (t_formacion, id_usuario, dni_usuario) references formacion_x_usuario (t_formacion, id_usuario, dni_usuario)
            on update cascade on delete cascade,
    constraint asignar_formacion_x_usuario_2
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table grupo_especial_epsp
(
    gespecial_id bigint unsigned not null,
    epsp_id      bigint unsigned not null,
    created_at   timestamp       not null,
    updated_at   timestamp       not null,
    primary key (gespecial_id, epsp_id),
    constraint grupo_especial_epsp_1
        foreign key (gespecial_id) references t_car_grupo_especial (id)
            on update cascade on delete cascade,
    constraint grupo_especial_epsp_2
        foreign key (epsp_id) references car_socio_epsp (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index epsp_id
    on grupo_especial_epsp (epsp_id);

create index gespecial_id
    on grupo_especial_epsp (gespecial_id);

create table grupo_x_usuario
(
    t_grupo     tinyint unsigned not null,
    id_usuario  bigint unsigned  not null,
    dni_usuario tinyint unsigned not null,
    vigente     tinyint unsigned not null,
    primary key (t_grupo, id_usuario, dni_usuario),
    constraint grupo_x_usuario_1
        foreign key (t_grupo) references t_grupo (id)
            on update cascade on delete cascade,
    constraint grupo_x_usuario_2
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table anular_grupo_x_usuario
(
    id              bigint unsigned auto_increment
        primary key,
    t_grupo         tinyint unsigned not null,
    id_usuario      bigint unsigned  not null,
    dni_usuario     tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    constraint anular_grupo_x_usuario_1
        foreign key (t_grupo, id_usuario, dni_usuario) references grupo_x_usuario (t_grupo, id_usuario, dni_usuario)
            on update cascade on delete cascade,
    constraint anular_grupo_x_usuario_2
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table asignar_grupo_x_usuario
(
    id              bigint unsigned auto_increment
        primary key,
    t_grupo         tinyint unsigned not null,
    id_usuario      bigint unsigned  not null,
    dni_usuario     tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    constraint asignar_grupo_x_usuario_1
        foreign key (t_grupo, id_usuario, dni_usuario) references grupo_x_usuario (t_grupo, id_usuario, dni_usuario)
            on update cascade on delete cascade,
    constraint asignar_grupo_x_usuario_2
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table hist_caja
(
    id                 bigint unsigned auto_increment
        primary key,
    sede               smallint unsigned            not null,
    caja               mediumint unsigned           not null,
    fecha_apertura     datetime                     not null,
    efectivo_inicial   decimal(14, 2) unsigned      not null,
    efectivo_recibido  decimal(14, 2) unsigned      null,
    efectivo_entregado decimal(14, 2) unsigned      null,
    efectivo_final     decimal(14, 2) unsigned      null,
    banco_recibido     decimal(14, 2) unsigned      null,
    banco_entregado    decimal(14, 2) unsigned      null,
    fecha_cierre       datetime                     null,
    observacion        varchar(255)                 null,
    vigente            tinyint unsigned default '1' not null,
    constraint hist_caja_1
        foreign key (sede, caja) references caja (sede, id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table inasistencia_evento
(
    evento          bigint unsigned              not null,
    id_usuario      bigint unsigned              not null,
    dni_usuario     tinyint unsigned             not null,
    observacion     varchar(255)                 null,
    vigente         tinyint unsigned default '1' not null,
    fecha_trans     datetime                     not null,
    id_responsable  bigint unsigned              not null,
    dni_responsable tinyint unsigned             not null,
    primary key (evento, id_usuario, dni_usuario),
    constraint inasistencia_evento_1
        foreign key (evento) references evento (id)
            on update cascade on delete cascade,
    constraint inasistencia_evento_2
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint inasistencia_evento_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci;

create table ingreso
(
    t_trans                tinyint unsigned        not null,
    sede                   smallint unsigned       not null,
    id                     bigint unsigned         not null,
    fecha_ingreso          date                    null,
    t_usuario              tinyint unsigned        not null,
    id_usuario             bigint unsigned         not null,
    dni_usuario            tinyint unsigned        not null,
    nombre_usuario         varchar(120)            not null,
    total                  decimal(14, 2) unsigned not null,
    observacion            varchar(255)            null,
    vigente                tinyint unsigned        not null,
    fecha_trans            datetime                not null,
    id_responsable         bigint unsigned         null,
    dni_responsable        tinyint unsigned        null,
    fecha_anular           datetime                null,
    observacion_anular     varchar(255)            null,
    id_responsable_anular  bigint unsigned         null,
    dni_responsable_anular tinyint unsigned        null,
    primary key (sede, id),
    constraint ingreso_1
        foreign key (t_trans, sede, id) references transaccion (t_trans, sede, id_trans)
            on update cascade on delete cascade,
    constraint ingreso_2
        foreign key (t_usuario) references t_usuario (id)
            on update cascade on delete cascade,
    constraint ingreso_3
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint ingreso_4
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint ingreso_5
        foreign key (id_responsable_anular, dni_responsable_anular) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table interviewer_settings
(
    id                     bigint unsigned auto_increment
        primary key,
    user_id                bigint unsigned               not null comment 'Usuario entrevistador',
    disponible             tinyint unsigned default '1'  not null comment 'Si está disponible para recibir asignaciones',
    capacidad_maxima       tinyint unsigned default '10' not null comment 'Número máximo de asignaciones simultáneas',
    notificaciones_activas tinyint unsigned default '1'  not null comment 'Si recibe notificaciones de nuevas asignaciones',
    notas                  text                          null comment 'Notas administrativas sobre el entrevistador',
    created_at             timestamp                     null,
    updated_at             timestamp                     null,
    constraint interviewer_settings_user_id_unique
        unique (user_id),
    constraint interviewer_settings_user_id_foreign
        foreign key (user_id) references usuario (id)
            on update cascade on delete cascade
)
    comment 'Configuración de usuarios que actúan como entrevistadores. Controla disponibilidad, capacidad y preferencias de notificación'
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index interviewer_settings_disponible
    on interviewer_settings (disponible);

create table maestro
(
    id                        bigint unsigned  not null,
    dni                       tinyint unsigned not null,
    t_maestro                 tinyint unsigned not null,
    est_maestro               tinyint unsigned not null,
    fecha_trans               datetime         not null,
    id_responsable            bigint unsigned  not null,
    dni_responsable           tinyint unsigned not null,
    fecha_modificar           datetime         null,
    id_responsable_modificar  bigint unsigned  null,
    dni_responsable_modificar tinyint unsigned null,
    primary key (id, dni),
    constraint maestro_1
        foreign key (id, dni) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint maestro_2
        foreign key (dni) references t_dni (id)
            on update cascade on delete cascade,
    constraint maestro_3
        foreign key (t_maestro) references t_maestro (id)
            on update cascade on delete cascade,
    constraint maestro_4
        foreign key (est_maestro) references est_maestro (id)
            on update cascade on delete cascade,
    constraint maestro_5
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint maestro_6
        foreign key (id_responsable_modificar, dni_responsable_modificar) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table materia
(
    id                        smallint unsigned auto_increment
        primary key,
    nombre                    varchar(80)                 not null,
    descripcion               varchar(1020)               null,
    creditos                  tinyint unsigned            not null,
    valor_matricula           decimal(14, 2) default 0.00 not null,
    est_materia               tinyint unsigned            not null,
    fecha_trans               datetime                    not null,
    id_responsable            bigint unsigned             not null,
    dni_responsable           tinyint unsigned            not null,
    fecha_modificar           datetime                    null,
    id_responsable_modificar  bigint unsigned             null,
    dni_responsable_modificar tinyint unsigned            null,
    constraint materia_1
        foreign key (est_materia) references est_materia (id)
            on update cascade on delete cascade,
    constraint materia_2
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint materia_3
        foreign key (id_responsable_modificar, dni_responsable_modificar) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table correquisito_materia
(
    materia         smallint unsigned not null,
    correquisito    smallint unsigned not null,
    fecha_trans     datetime          not null,
    id_responsable  bigint unsigned   not null,
    dni_responsable tinyint unsigned  not null,
    primary key (materia, correquisito),
    constraint correquisito_materia_1
        foreign key (materia) references materia (id)
            on update cascade on delete cascade,
    constraint correquisito_materia_2
        foreign key (correquisito) references materia (id)
            on update cascade on delete cascade,
    constraint correquisito_materia_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    charset = latin1
    row_format = COMPACT;

create table grupo
(
    id                        smallint unsigned not null
        primary key,
    materia                   smallint unsigned not null,
    sede                      smallint unsigned not null,
    fecha_inicio              date              null,
    fecha_fin                 date              null,
    id_maestro                bigint unsigned   null,
    dni_maestro               tinyint unsigned  null,
    est_grupo                 tinyint unsigned  null,
    fecha_trans               datetime          not null,
    id_responsable            bigint unsigned   not null,
    dni_responsable           tinyint unsigned  not null,
    fecha_modificar           datetime          null,
    id_responsable_modificar  bigint unsigned   null,
    dni_responsable_modificar tinyint unsigned  null,
    title                     varchar(100)      null,
    constraint grupo_1
        foreign key (materia) references materia (id)
            on update cascade on delete cascade,
    constraint grupo_2
        foreign key (sede) references sede (id)
            on update cascade on delete cascade,
    constraint grupo_3
        foreign key (id_maestro, dni_maestro) references maestro (id, dni)
            on update cascade on delete cascade,
    constraint grupo_4
        foreign key (est_grupo) references est_grupo (id)
            on update cascade on delete cascade,
    constraint grupo_5
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint grupo_6
        foreign key (id_responsable_modificar, dni_responsable_modificar) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table grupo_x_asistente
(
    grupo           smallint unsigned            not null,
    id_asistente    bigint unsigned  default '0' not null,
    dni_asistente   tinyint unsigned default '0' not null,
    fecha_trans     datetime                     not null,
    id_responsable  bigint unsigned              not null,
    dni_responsable tinyint unsigned             not null,
    primary key (grupo, id_asistente, dni_asistente),
    constraint grupo_x_asistente_1
        foreign key (grupo) references grupo (id)
            on update cascade on delete cascade,
    constraint grupo_x_asistente_2
        foreign key (id_asistente, dni_asistente) references maestro (id, dni)
            on update cascade on delete cascade,
    constraint grupo_x_asistente_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    charset = latin1
    row_format = COMPACT;

create table grupo_x_monitor
(
    grupo           smallint unsigned            not null,
    id_monitor      bigint unsigned  default '0' not null,
    dni_monitor     tinyint unsigned default '0' not null,
    fecha_trans     datetime                     not null,
    id_responsable  bigint unsigned              not null,
    dni_responsable tinyint unsigned             not null,
    primary key (grupo, id_monitor, dni_monitor),
    constraint grupo_x_monitor_1
        foreign key (grupo) references grupo (id)
            on update cascade on delete cascade,
    constraint grupo_x_monitor_2
        foreign key (id_monitor, dni_monitor) references maestro (id, dni)
            on update cascade on delete cascade,
    constraint grupo_x_monitor_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    charset = latin1
    row_format = COMPACT;

create table material_formacion
(
    id              bigint unsigned auto_increment
        primary key,
    titulo          varchar(80)                  not null,
    descripcion     varchar(1023)                not null,
    formacion       tinyint unsigned             not null,
    t_material      tinyint unsigned             not null,
    url             varchar(255)                 not null,
    vigente         tinyint unsigned default '1' not null,
    fecha_trans     datetime                     not null,
    id_responsable  bigint unsigned              not null,
    dni_responsable tinyint unsigned             not null,
    constraint material_formacion_1
        foreign key (formacion) references t_formacion (id)
            on update cascade on delete cascade,
    constraint material_formacion_2
        foreign key (t_material) references t_material (id)
            on update cascade on delete cascade,
    constraint material_formacion_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table anular_material_formacion
(
    id              bigint unsigned auto_increment
        primary key,
    material        bigint unsigned  not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    constraint anular_material_formacion_1
        foreign key (material) references material_formacion (id)
            on update cascade on delete cascade,
    constraint anular_material_formacion_2
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table material_materia
(
    id              bigint unsigned auto_increment
        primary key,
    titulo          varchar(80)                  not null,
    descripcion     varchar(1023)                not null,
    formacion       tinyint unsigned             not null,
    t_material      tinyint unsigned             not null,
    url             varchar(255)                 not null,
    vigente         tinyint unsigned default '1' not null,
    fecha_trans     datetime                     not null,
    id_responsable  bigint unsigned              not null,
    dni_responsable tinyint unsigned             not null,
    constraint material_materia_1
        foreign key (formacion) references t_formacion (id)
            on update cascade on delete cascade,
    constraint material_materia_2
        foreign key (t_material) references t_material (id)
            on update cascade on delete cascade,
    constraint material_materia_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table matricula_materia
(
    t_trans                tinyint unsigned              not null,
    sede                   smallint unsigned             not null,
    id                     bigint unsigned               not null,
    grupo                  smallint unsigned             not null,
    id_alumno              bigint unsigned               null,
    dni_alumno             tinyint unsigned              null,
    est_matricula          tinyint unsigned              not null,
    valor_matricula        decimal(14, 2)   default 0.00 not null,
    pdte_cobro             decimal(14, 2)   default 0.00 not null,
    vigente                tinyint unsigned default '1'  not null,
    fecha_trans            datetime                      not null,
    id_responsable         bigint unsigned               not null,
    dni_responsable        tinyint unsigned              not null,
    fecha_anular           datetime                      null,
    observacion_anular     varchar(255)                  null,
    id_responsable_anular  bigint unsigned               null,
    dni_responsable_anular tinyint unsigned              null,
    observacion            varchar(255)                  null,
    primary key (sede, id),
    constraint matricula_materia_1
        foreign key (t_trans, sede, id) references transaccion (t_trans, sede, id_trans)
            on update cascade on delete cascade,
    constraint matricula_materia_2
        foreign key (sede) references sede (id)
            on update cascade on delete cascade,
    constraint matricula_materia_3
        foreign key (grupo) references grupo (id)
            on update cascade on delete cascade,
    constraint matricula_materia_4
        foreign key (id_alumno, dni_alumno) references alumno (id, dni)
            on update cascade on delete cascade,
    constraint matricula_materia_5
        foreign key (est_matricula) references est_matricula_materia (id)
            on update cascade on delete cascade,
    constraint matricula_materia_6
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint matricula_materia_7
        foreign key (id_responsable_anular, dni_responsable_anular) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create index matricula_materia_i1
    on matricula_materia (id);

create index matricula_materia_i2
    on matricula_materia (vigente);

create index matricula_materia_i3
    on matricula_materia (pdte_cobro);

create index matricula_materia_i4
    on matricula_materia (fecha_trans);

create table miembro
(
    id              bigint unsigned  not null,
    dni             tinyint unsigned not null,
    estado          tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    primary key (id, dni),
    constraint miembro_1
        foreign key (id, dni) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint miembro_2
        foreign key (dni) references t_dni (id)
            on update cascade on delete cascade,
    constraint miembro_3
        foreign key (estado) references est_miembro (id)
            on update cascade on delete cascade,
    constraint miembro_4
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table movimiento_dinero
(
    id                    bigint unsigned auto_increment
        primary key,
    t_trans               tinyint unsigned             not null,
    trans_vigente_anulada tinyint unsigned default '1' not null,
    sede                  smallint unsigned            not null,
    id_trans              bigint unsigned              not null,
    t_usuario             tinyint unsigned             not null,
    id_usuario            bigint unsigned              null,
    dni_usuario           tinyint unsigned             null,
    credito_debito        tinyint unsigned             not null,
    total                 decimal(14, 2) unsigned      not null,
    sede_caja             smallint unsigned            not null,
    caja                  mediumint unsigned           not null,
    efectivo_caja         decimal(14, 2) unsigned      null,
    cuenta                mediumint unsigned           null,
    valor_cuenta          decimal(14, 2) unsigned      null,
    observacion           varchar(255)                 null,
    fecha_trans           datetime                     not null,
    id_responsable        bigint unsigned              null,
    dni_responsable       tinyint unsigned             null,
    constraint movimiento_dinero_1
        foreign key (t_trans, sede, id_trans) references transaccion (t_trans, sede, id_trans)
            on update cascade on delete cascade,
    constraint movimiento_dinero_2
        foreign key (t_usuario) references t_usuario (id)
            on update cascade on delete cascade,
    constraint movimiento_dinero_3
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint movimiento_dinero_4
        foreign key (sede_caja, caja) references caja (sede, id)
            on update cascade on delete cascade,
    constraint movimiento_dinero_5
        foreign key (cuenta, sede_caja, caja) references cuenta_x_caja (cuenta, sede, caja)
            on update cascade on delete cascade,
    constraint movimiento_dinero_6
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table medio_pago
(
    id                     bigint unsigned auto_increment
        primary key,
    t_trans                tinyint unsigned        not null,
    sede                   smallint unsigned       not null,
    id_trans               bigint unsigned         null,
    t_medio_pago           tinyint unsigned        not null,
    valor                  decimal(14, 2) unsigned not null,
    movimiento_dinero      bigint unsigned         null,
    sede_caja              smallint unsigned       not null,
    caja                   mediumint unsigned      null,
    efectivo_caja          decimal(14, 2) unsigned null,
    cuenta                 mediumint unsigned      null,
    valor_cuenta           decimal(14, 2) unsigned null,
    observacion            varchar(60)             not null,
    vigente                tinyint unsigned        not null,
    fecha_trans            datetime                not null,
    id_responsable         bigint unsigned         null,
    dni_responsable        tinyint unsigned        null,
    fecha_anular           datetime                null,
    observacion_anular     varchar(255)            null,
    id_responsable_anular  bigint unsigned         null,
    dni_responsable_anular tinyint unsigned        null,
    constraint medio_pago_f1
        foreign key (t_trans, sede, id_trans) references transaccion (t_trans, sede, id_trans)
            on update cascade on delete cascade,
    constraint medio_pago_f2
        foreign key (t_medio_pago) references t_medio_pago (id)
            on update cascade on delete cascade,
    constraint medio_pago_f3
        foreign key (movimiento_dinero) references movimiento_dinero (id)
            on update cascade on delete cascade,
    constraint medio_pago_f4
        foreign key (sede_caja, caja) references caja (sede, id)
            on update cascade on delete cascade,
    constraint medio_pago_f5
        foreign key (cuenta, sede_caja, caja) references cuenta_x_caja (cuenta, sede, caja)
            on update cascade on delete cascade,
    constraint medio_pago_f6
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint medio_pago_f7
        foreign key (id_responsable_anular, dni_responsable_anular) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create index movimiento_dinero_i2
    on movimiento_dinero (total);

create table nota_grupo
(
    grupo       smallint unsigned not null,
    id          tinyint unsigned  not null,
    porcentaje  smallint unsigned not null,
    descripcion varchar(40)       not null,
    primary key (grupo, id),
    constraint nota_grupo_1
        foreign key (grupo) references grupo (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table nota_alumno
(
    sede              smallint unsigned                   not null,
    matricula_materia bigint unsigned                     not null,
    grupo             smallint unsigned                   not null,
    nota              tinyint unsigned                    not null,
    calificacion      decimal(5, 2) unsigned default 0.00 not null,
    primary key (sede, matricula_materia, grupo, nota),
    constraint nota_alumno_1
        foreign key (sede, matricula_materia) references matricula_materia (sede, id)
            on update cascade on delete cascade,
    constraint nota_alumno_2
        foreign key (grupo, nota) references nota_grupo (grupo, id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table oferta_empleo_epsp
(
    oferta_empleo_id bigint unsigned not null,
    epsp_id          bigint unsigned not null,
    primary key (oferta_empleo_id, epsp_id),
    constraint oferta_empleo_epsp_epsp_id_foreign
        foreign key (epsp_id) references car_socio_epsp (id)
            on update cascade on delete cascade,
    constraint oferta_empleo_epsp_oferta_empleo_id_foreign
        foreign key (oferta_empleo_id) references ofertas_empleo (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table predicador_x_evento
(
    evento         bigint unsigned  not null,
    id_predicador  bigint unsigned  not null,
    dni_predicador tinyint unsigned not null,
    vigente        tinyint unsigned not null,
    primary key (evento, id_predicador, dni_predicador),
    constraint predicador_x_evento_1
        foreign key (evento) references evento (id)
            on update cascade on delete cascade,
    constraint predicador_x_evento_2
        foreign key (id_predicador, dni_predicador) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table prerrequisito_materia
(
    materia         smallint unsigned not null,
    prerrequisito   smallint unsigned not null,
    fecha_trans     datetime          not null,
    id_responsable  bigint unsigned   not null,
    dni_responsable tinyint unsigned  not null,
    primary key (materia, prerrequisito),
    constraint prerrequisito_materia_1
        foreign key (materia) references materia (id)
            on update cascade on delete cascade,
    constraint prerrequisito_materia_2
        foreign key (prerrequisito) references materia (id)
            on update cascade on delete cascade,
    constraint prerrequisito_materia_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    charset = latin1
    row_format = COMPACT;

create table professional_experiences
(
    id                  bigint unsigned auto_increment
        primary key,
    academic_profile_id bigint unsigned      not null,
    company             varchar(255)         not null,
    position            varchar(255)         not null,
    description         text                 null,
    skills_used         json                 null,
    start_date          date                 not null,
    end_date            date                 null,
    is_current          tinyint(1) default 0 not null,
    created_at          timestamp            null,
    updated_at          timestamp            null,
    constraint professional_experiences_academic_profile_id_foreign
        foreign key (academic_profile_id) references academic_profiles (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table programa
(
    id              smallint unsigned auto_increment
        primary key,
    nombre          varchar(80)                 not null,
    descripcion     varchar(1020)               null,
    creditos        smallint                    not null,
    valor_matricula decimal(14, 2) default 0.00 not null,
    fecha_trans     datetime                    not null,
    id_responsable  bigint unsigned             not null,
    dni_responsable tinyint unsigned            not null,
    vigente         tinyint unsigned            not null,
    constraint programa_1
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table matricula_programa
(
    t_trans                   tinyint unsigned              not null,
    sede                      smallint unsigned             not null,
    id                        bigint unsigned               not null,
    programa                  smallint unsigned             not null,
    id_alumno                 bigint unsigned               null,
    dni_alumno                tinyint unsigned              null,
    est_matricula             tinyint unsigned              not null,
    observacion_estado        varchar(500)                  null comment 'Razón del estado (reprobado/desertor)',
    valor_matricula           decimal(14, 2)   default 0.00 not null,
    pdte_cobro                decimal(14, 2)   default 0.00 not null,
    vigente                   tinyint unsigned default '1'  not null,
    fecha_trans               datetime                      not null,
    id_responsable            bigint unsigned               not null,
    dni_responsable           tinyint unsigned              not null,
    fecha_modificar           datetime                      null,
    id_responsable_modificar  bigint unsigned               null,
    dni_responsable_modificar tinyint unsigned              null,
    primary key (sede, id),
    constraint matricula_programa_1
        foreign key (t_trans, sede, id) references transaccion (t_trans, sede, id_trans)
            on update cascade on delete cascade,
    constraint matricula_programa_2
        foreign key (sede) references sede (id)
            on update cascade on delete cascade,
    constraint matricula_programa_3
        foreign key (programa) references programa (id)
            on update cascade on delete cascade,
    constraint matricula_programa_4
        foreign key (id_alumno, dni_alumno) references alumno (id, dni)
            on update cascade on delete cascade,
    constraint matricula_programa_5
        foreign key (est_matricula) references est_matricula_programa (id)
            on update cascade on delete cascade,
    constraint matricula_programa_6
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint matricula_programa_7
        foreign key (id_responsable_modificar, dni_responsable_modificar) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table programa_x_materia
(
    programa        smallint unsigned not null,
    materia         smallint unsigned not null,
    fecha_trans     datetime          not null,
    id_responsable  bigint unsigned   not null,
    dni_responsable tinyint unsigned  not null,
    obs             char(50)          null,
    primary key (programa, materia),
    constraint programa_x_materia_1
        foreign key (programa) references programa (id)
            on update cascade on delete cascade,
    constraint programa_x_materia_2
        foreign key (materia) references materia (id)
            on update cascade on delete cascade,
    constraint programa_x_materia_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    charset = latin1
    row_format = COMPACT;

create table registro_evento
(
    evento             bigint unsigned                                                                            not null comment 'Identificador del evento, se encuentra relacionada con la estructura de evento columna id',
    id_usuario         bigint unsigned                                                                            not null comment 'Número de identificación del usuario inscrito al evento, relacionado con la estructura usuario campo id',
    dni_usuario        tinyint unsigned                                                                           not null comment 'Tipo de identificación del usuario inscrito al evento. 1-Cedula de ciudadanía',
    vigente            tinyint unsigned                                                       default '1'         not null comment '0- Indica que el registro esta borrado o anulado , 1- El registro se encuentra activo',
    causal_cancelacion varchar(6)                                                                                 null comment '(SINJUS) Sin Justificación, (ENFERM) Enfermedad (SITFAM) Situación familiar (SITLAB) Situación laboral (SEMINA) Otro seminario en la comunidad (OTRCAU) Otra Causa ',
    fecha_cancelacion  datetime                                                                                   null comment 'Fecha de cancelación del evento',
    fecha_trans        datetime                                                                                   null comment 'Fecha en la cual se realizó el registro al evento',
    id_responsable     bigint unsigned                                                                            not null comment 'Identificación de la persona responsable del evento',
    dni_responsable    tinyint unsigned                                                                           not null comment 'Tipo de identificación de la persona responsable del evento',
    fecha_novedad      timestamp                                                                                  null comment 'Fecha y hora de llegada al evento',
    observacion        varchar(200)                                                                               null comment 'Observación con la cual se amplia la información ',
    estado             enum ('PENDIENTE', 'CONFIRMADO', 'NO_ASISTIO', 'CANCELADO', 'ASISTIO') default 'PENDIENTE' not null,
    primary key (evento, id_usuario, dni_usuario),
    constraint registro_evento_1
        foreign key (evento) references evento (id)
            on update cascade on delete cascade,
    constraint registro_evento_2
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint registro_evento_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table reporte_miembro
(
    id              bigint unsigned auto_increment
        primary key,
    id_miembro      bigint unsigned   not null,
    dni_miembro     tinyint unsigned  not null,
    t_reporte       tinyint unsigned  not null,
    sede            smallint unsigned not null,
    reporte         varchar(1020)     not null,
    fecha_trans     datetime          not null,
    id_responsable  bigint unsigned   not null,
    dni_responsable tinyint unsigned  not null,
    vigente         tinyint unsigned  not null,
    constraint reporte_miembro_1
        foreign key (id_miembro, dni_miembro) references miembro (id, dni)
            on update cascade on delete cascade,
    constraint reporte_miembro_2
        foreign key (t_reporte) references t_reporte (id)
            on update cascade on delete cascade,
    constraint reporte_miembro_3
        foreign key (sede) references sede (id)
            on update cascade on delete cascade,
    constraint reporte_miembro_4
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table salon
(
    sede                      smallint unsigned not null,
    id                        tinyint unsigned  not null,
    capacidad                 tinyint unsigned  not null,
    descripcion               varchar(1020)     null,
    est_salon                 tinyint unsigned  not null,
    fecha_trans               datetime          not null,
    id_responsable            bigint unsigned   not null,
    dni_responsable           tinyint unsigned  not null,
    fecha_modificar           datetime          null,
    id_responsable_modificar  bigint unsigned   null,
    dni_responsable_modificar tinyint unsigned  null,
    primary key (sede, id),
    constraint salon_1
        foreign key (sede) references sede (id)
            on update cascade on delete cascade,
    constraint salon_2
        foreign key (est_salon) references est_salon (id)
            on update cascade on delete cascade,
    constraint salon_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint salon_4
        foreign key (id_responsable_modificar, dni_responsable_modificar) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table horario_grupo
(
    grupo       smallint unsigned not null,
    id          tinyint unsigned  not null,
    sede        smallint unsigned not null,
    salon       tinyint unsigned  not null,
    dia         tinyint unsigned  not null,
    hora_inicio time              not null,
    hora_fin    time              not null,
    primary key (grupo, id),
    constraint horario_grupo_1
        foreign key (grupo) references grupo (id)
            on update cascade on delete cascade,
    constraint horario_grupo_2
        foreign key (sede, salon) references salon (sede, id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table clase
(
    grupo                      smallint unsigned not null,
    id                         tinyint unsigned  not null,
    horario                    tinyint unsigned  not null,
    fecha_inicio               datetime          not null,
    fecha_fin                  datetime          not null,
    est_clase                  tinyint unsigned  not null,
    url_video                  varchar(255)      null,
    fecha_asistencia           datetime          null,
    fecha_cancelar             datetime          null,
    observacion_cancelar       varchar(255)      null,
    id_responsable_cancelar    bigint unsigned   null,
    dni_responsable_cancelar   tinyint unsigned  null,
    id_responsable_asistencia  bigint unsigned   null,
    dni_responsable_asistencia tinyint unsigned  null,
    primary key (grupo, id),
    constraint clase_1
        foreign key (grupo) references grupo (id)
            on update cascade on delete cascade,
    constraint clase_2
        foreign key (grupo, horario) references horario_grupo (grupo, id)
            on update cascade on delete cascade,
    constraint clase_3
        foreign key (est_clase) references est_clase (id)
            on update cascade on delete cascade,
    constraint clase_4
        foreign key (id_responsable_cancelar, dni_responsable_cancelar) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint clase_5
        foreign key (id_responsable_asistencia, dni_responsable_asistencia) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table asistencia_clase
(
    grupo           smallint unsigned                        not null,
    clase           tinyint unsigned                         not null,
    id_alumno       bigint unsigned                          not null,
    dni_alumno      tinyint unsigned                         not null,
    tipo_asistencia enum ('PRESCENCIAL', 'VIRTUAL', 'VIDEO') null comment '1 prescencial 2 es virtual',
    created_at      timestamp                                null,
    updated_at      timestamp                                null,
    cantidad        tinyint                                  null,
    primary key (grupo, clase, id_alumno, dni_alumno),
    constraint asistencia_clase_1
        foreign key (grupo, clase) references clase (grupo, id)
            on update cascade on delete cascade,
    constraint asistencia_clase_2
        foreign key (id_alumno, dni_alumno) references alumno (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create index clase_i1
    on clase (fecha_inicio);

create index clase_i2
    on clase (fecha_fin);

alter table sede
    add constraint sede_3
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade;

create table servicios_comunitarios
(
    id                 bigint unsigned auto_increment
        primary key,
    epsp_id            bigint unsigned      not null,
    presta_servicio    tinyint(1) default 0 not null,
    estado             tinyint(1) default 0 not null,
    fecha_inicio       date                 null,
    servicio_prestado  varchar(255)         null,
    servidor_inmediato varchar(255)         null,
    fecha_terminacion  date                 null,
    motivo_terminacion text                 null,
    tiempo_semanal     int                  null,
    labores            text                 null,
    created_at         timestamp            null,
    updated_at         timestamp            null,
    constraint servicios_comunitarios_epsp_id_foreign
        foreign key (epsp_id) references car_socio_epsp (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table direcciones_preferidas
(
    id                      bigint unsigned auto_increment
        primary key,
    servicio_comunitario_id bigint unsigned not null,
    direccion_id            varchar(255)    not null,
    tipo                    varchar(255)    not null,
    observacion             text            null,
    created_at              timestamp       null,
    updated_at              timestamp       null,
    constraint direcciones_preferidas_servicio_comunitario_id_foreign
        foreign key (servicio_comunitario_id) references servicios_comunitarios (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table suscripciones_pastorales
(
    id                  bigint unsigned auto_increment
        primary key,
    usuario_id          bigint unsigned                  not null,
    usuario_asignado_id bigint unsigned                  null,
    type_attention      enum ('PRUEBA', 'ASESORIA')      not null,
    fecha_suscripcion   date                             not null,
    motivo_consulta     varchar(255)                     not null,
    fecha_asignacion    date                             null,
    tamizajeobs         varchar(255)                     null,
    observacion         varchar(250)                     null,
    estado              varchar(255) default 'pendiente' not null,
    created_at          timestamp                        null,
    updated_at          timestamp                        null,
    constraint suscripciones_pastorales_usuario_asignado_id_foreign
        foreign key (usuario_asignado_id) references usuario (id),
    constraint suscripciones_pastorales_usuario_id_foreign
        foreign key (usuario_id) references usuario (id)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table consultas_pastorales
(
    id             bigint unsigned auto_increment
        primary key,
    suscripcion_id bigint unsigned                                                                  not null,
    consultor_id   bigint unsigned                                                                  not null,
    fecha_atencion datetime                                                                         not null,
    observaciones  text                                                                             null,
    estado         enum ('pendiente', 'realizada', 'cancelada', 'reprogramada') default 'pendiente' not null,
    created_at     timestamp                                                                        null,
    updated_at     timestamp                                                                        null,
    constraint consultas_pastorales_consultor_id_foreign
        foreign key (consultor_id) references consultores_pastorales (id),
    constraint consultas_pastorales_suscripcion_id_foreign
        foreign key (suscripcion_id) references suscripciones_pastorales (id)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table detalles_atencion_pastoral
(
    id                      bigint unsigned auto_increment
        primary key,
    usuario_asignado_id     bigint unsigned                                                   not null,
    suscripcion_pastoral_id bigint unsigned                                                   not null,
    detalle                 text                                                              null,
    fecha_atencion          date                                                              not null,
    observacion             varchar(255)                                                      null,
    estado                  enum ('pendiente', 'completada', 'cancelada') default 'pendiente' not null,
    created_at              timestamp                                                         null,
    updated_at              timestamp                                                         null,
    constraint detalles_atencion_pastoral_suscripcion_pastoral_id_foreign
        foreign key (suscripcion_pastoral_id) references suscripciones_pastorales (id)
            on delete cascade,
    constraint detalles_atencion_pastoral_usuario_asignado_id_foreign
        foreign key (usuario_asignado_id) references usuario (id)
            on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create table t_egreso
(
    id                        smallint unsigned            not null
        primary key,
    tipo                      varchar(255)                 not null,
    visible_trans             tinyint unsigned default '1' not null,
    retencion                 tinyint unsigned default '0' not null,
    vigente                   tinyint unsigned             not null,
    fecha_trans               datetime                     not null,
    id_responsable            bigint unsigned              null,
    dni_responsable           tinyint unsigned             null,
    fecha_modificar           datetime                     null,
    id_responsable_modificar  bigint unsigned              null,
    dni_responsable_modificar tinyint unsigned             null,
    fecha_anular              datetime                     null,
    observacion_anular        varchar(255)                 null,
    id_responsable_anular     bigint unsigned              null,
    dni_responsable_anular    tinyint unsigned             null,
    constraint t_egreso_1
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint t_egreso_2
        foreign key (id_responsable_modificar, dni_responsable_modificar) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint t_egreso_3
        foreign key (id_responsable_anular, dni_responsable_anular) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table egreso
(
    t_trans                tinyint unsigned        not null,
    sede                   smallint unsigned       not null,
    prefijo                char(4)                 not null,
    id                     bigint unsigned         not null,
    fecha_egreso           date                    null,
    t_usuario              tinyint unsigned        not null,
    id_usuario             bigint unsigned         not null,
    dni_usuario            tinyint unsigned        not null,
    nombre_usuario         varchar(120)            not null,
    pais_usuario           smallint unsigned       not null,
    provincia_usuario      smallint unsigned       null,
    ciudad_usuario         varchar(60)             null,
    direccion_usuario      varchar(80)             null,
    telefono_usuario       varchar(80)             null,
    t_egreso               smallint unsigned       not null,
    descripcion            varchar(120)            not null,
    total                  decimal(14, 2) unsigned not null,
    t_trans_ref            tinyint unsigned        null,
    sede_ref               smallint unsigned       null,
    id_trans_ref           bigint unsigned         null,
    observacion            varchar(255)            null,
    vigente                tinyint unsigned        not null,
    fecha_trans            datetime                not null,
    id_responsable         bigint unsigned         null,
    dni_responsable        tinyint unsigned        null,
    fecha_anular           datetime                null,
    observacion_anular     varchar(255)            null,
    id_responsable_anular  bigint unsigned         null,
    dni_responsable_anular tinyint unsigned        null,
    primary key (sede, id),
    constraint egreso_1
        foreign key (t_trans, sede, id) references transaccion (t_trans, sede, id_trans)
            on update cascade on delete cascade,
    constraint egreso_2
        foreign key (t_usuario) references t_usuario (id)
            on update cascade on delete cascade,
    constraint egreso_3
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint egreso_4
        foreign key (t_egreso) references t_egreso (id)
            on update cascade on delete cascade,
    constraint egreso_5
        foreign key (t_trans_ref, sede_ref, id_trans_ref) references transaccion (t_trans, sede, id_trans)
            on update cascade on delete cascade,
    constraint egreso_6
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint egreso_7
        foreign key (id_responsable_anular, dni_responsable_anular) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create index egreso_i1
    on egreso (total);

create index t_egreso_i1
    on t_egreso (tipo);

create table t_gestion
(
    id          tinyint unsigned auto_increment
        primary key,
    tipo        varchar(60)                         not null,
    created_at  timestamp                           null,
    updated_at  timestamp                           null,
    usuario_id  bigint unsigned  default '71770935' not null,
    dni_id      tinyint unsigned default '1'        not null,
    vigente     tinyint unsigned default '1'        not null,
    responsable varchar(50)                         null comment 'provisional mientras se configura otra tabla',
    constraint fk_t_gestion_usuario
        foreign key (usuario_id, dni_id) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table gestion_categories
(
    id            bigint unsigned auto_increment
        primary key,
    t_gestion_id  tinyint unsigned     not null,
    category_name varchar(100)         not null,
    description   text                 null,
    vigente       tinyint(1) default 1 not null,
    created_at    timestamp            null,
    updated_at    timestamp            null,
    constraint unique_gestion_category
        unique (t_gestion_id, category_name),
    constraint fk_gestion_categories_t_gestion
        foreign key (t_gestion_id) references t_gestion (id)
            on update cascade on delete cascade
)
    comment 'Categorías/subcategorías flexibles para cada tipo de gestión' engine = InnoDB
                                                                           collate = utf8mb3_spanish_ci;

create index idx_gestion_categories_t_gestion
    on gestion_categories (t_gestion_id);

create index idx_gestion_categories_vigente
    on gestion_categories (vigente);

create table gestion_usuario_categories
(
    id            bigint unsigned auto_increment
        primary key,
    id_usuario    bigint unsigned  not null comment 'ID del usuario',
    t_gestion     tinyint unsigned not null comment 'ID del tipo de gestión',
    category_name varchar(100)     not null comment 'Nombre de la categoría',
    created_at    timestamp        null,
    updated_at    timestamp        null,
    constraint unique_usuario_gestion_category
        unique (id_usuario, t_gestion, category_name),
    constraint fk_guc_t_gestion
        foreign key (t_gestion) references t_gestion (id)
            on update cascade on delete cascade,
    constraint fk_guc_usuario
        foreign key (id_usuario) references usuario (id)
            on update cascade on delete cascade
)
    comment 'Categorías individuales asignadas a usuarios por tipo de gestión' engine = InnoDB
                                                                               collate = utf8mb3_spanish_ci;

create index idx_category_name
    on gestion_usuario_categories (category_name);

create index idx_gestion_category
    on gestion_usuario_categories (t_gestion, category_name);

create index idx_usuario_gestion
    on gestion_usuario_categories (id_usuario, t_gestion);

create table gestion_x_usuario
(
    t_gestion             tinyint unsigned  not null,
    id_usuario            bigint unsigned   not null,
    dni_usuario           tinyint unsigned  not null,
    funciones             varchar(200)      null,
    observacion           varchar(200)      null,
    observacion_descarte  text              null comment 'Razón por la cual se descartó o pospuso el servicio',
    servidor_inmediato    varchar(100)      null,
    tiempo_invertido_mes  varchar(200)      null,
    fecha_inicio          timestamp         null,
    fecha_retiro          timestamp         null,
    disponible_servir     tinyint default 0 not null,
    tiempo_disponibilidad varchar(100)      null,
    category              varchar(100)      null comment 'Subcategoría flexible para clasificación',
    vigente               tinyint unsigned  not null,
    created_at            timestamp         null,
    updated_at            timestamp         null,
    primary key (t_gestion, id_usuario, dni_usuario),
    constraint gestion_x_usuario_1
        foreign key (t_gestion) references t_gestion (id)
            on update cascade on delete cascade,
    constraint gestion_x_usuario_2
        foreign key (id_usuario, dni_usuario) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table anular_gestion_x_usuario
(
    id              bigint unsigned auto_increment
        primary key,
    t_gestion       tinyint unsigned not null,
    id_usuario      bigint unsigned  not null,
    dni_usuario     tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    constraint anular_gestion_x_usuario_1
        foreign key (t_gestion, id_usuario, dni_usuario) references gestion_x_usuario (t_gestion, id_usuario, dni_usuario)
            on update cascade on delete cascade,
    constraint anular_gestion_x_usuario_2
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table asignar_gestion_x_usuario
(
    id              bigint unsigned auto_increment
        primary key,
    t_gestion       tinyint unsigned not null,
    id_usuario      bigint unsigned  not null,
    dni_usuario     tinyint unsigned not null,
    fecha_trans     datetime         not null,
    id_responsable  bigint unsigned  not null,
    dni_responsable tinyint unsigned not null,
    constraint asignar_gestion_x_usuario_1
        foreign key (t_gestion, id_usuario, dni_usuario) references gestion_x_usuario (t_gestion, id_usuario, dni_usuario)
            on update cascade on delete cascade,
    constraint asignar_gestion_x_usuario_2
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table gestion_x_usuario_responsable
(
    t_gestion     tinyint unsigned             not null,
    user_id       bigint unsigned              not null,
    vigente       tinyint unsigned default '1' not null,
    created_at    timestamp                    null,
    updated_at    timestamp                    null,
    fecha_retiro  timestamp                    null,
    observaciones varchar(200)                 null,
    primary key (t_gestion, user_id),
    constraint gestion_x_usuario_responsable_1
        foreign key (t_gestion) references t_gestion (id)
            on update cascade on delete cascade,
    constraint gestion_x_usuario_responsable_2
        foreign key (user_id) references usuario (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create index idx_t_gestion_dni_id
    on t_gestion (dni_id);

create index idx_t_gestion_usuario_id
    on t_gestion (usuario_id);

create table t_ingreso
(
    id                        smallint unsigned not null
        primary key,
    tipo                      varchar(255)      not null,
    vigente                   tinyint unsigned  not null,
    fecha_trans               datetime          not null,
    id_responsable            bigint unsigned   null,
    dni_responsable           tinyint unsigned  null,
    fecha_modificar           datetime          null,
    id_responsable_modificar  bigint unsigned   null,
    dni_responsable_modificar tinyint unsigned  null,
    fecha_anular              datetime          null,
    observacion_anular        varchar(255)      null,
    id_responsable_anular     bigint unsigned   null,
    dni_responsable_anular    tinyint unsigned  null,
    constraint t_ingreso_1
        foreign key (id_responsable, dni_responsable) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint t_ingreso_2
        foreign key (id_responsable_modificar, dni_responsable_modificar) references usuario (id, dni)
            on update cascade on delete cascade,
    constraint t_ingreso_3
        foreign key (id_responsable_anular, dni_responsable_anular) references usuario (id, dni)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create table detalle_ingreso
(
    id           bigint unsigned auto_increment
        primary key,
    sede_ingreso smallint unsigned not null,
    id_ingreso   bigint unsigned   not null,
    t_ingreso    smallint unsigned not null,
    descripcion  varchar(120)      not null,
    total        decimal(14, 2)    not null,
    t_trans_ref  tinyint unsigned  null,
    sede_ref     smallint unsigned null,
    id_trans_ref bigint unsigned   null,
    constraint detalle_ingreso_1
        foreign key (sede_ingreso, id_ingreso) references ingreso (sede, id)
            on update cascade on delete cascade,
    constraint detalle_ingreso_2
        foreign key (t_ingreso) references t_ingreso (id)
            on update cascade on delete cascade,
    constraint detalle_ingreso_3
        foreign key (t_trans_ref, sede_ref, id_trans_ref) references transaccion (t_trans, sede, id_trans)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci
    row_format = COMPACT;

create index t_ingreso_i1
    on t_ingreso (tipo);

create table user_task_assignments
(
    id                  bigint unsigned auto_increment
        primary key,
    user_id             bigint unsigned                                                                                    not null comment 'Usuario al que se le realizará la entrevista/tarea',
    interviewer_user_id bigint unsigned                                                                                    not null comment 'Usuario entrevistador asignado',
    task_type_id        bigint unsigned                                                                                    not null comment 'Tipo de tarea asignada',
    admin_user_id       bigint unsigned                                                                                    not null comment 'Usuario administrador que asignó la tarea',
    status              enum ('asignado', 'iniciado', 'terminado', 'no_contactado', 'cancelado') default 'asignado'        not null comment 'Estado actual de la tarea',
    assigned_at         timestamp                                                                default CURRENT_TIMESTAMP not null comment 'Fecha de asignación',
    started_at          timestamp                                                                                          null comment 'Fecha de inicio',
    completed_at        timestamp                                                                                          null comment 'Fecha de finalización',
    interview_date      timestamp                                                                                          null comment 'Fecha programada/realizada de la entrevista',
    notes               text                                                                                               null comment 'Observaciones generales',
    created_at          timestamp                                                                                          null,
    updated_at          timestamp                                                                                          null,
    constraint user_task_assignments_admin_user_id_foreign
        foreign key (admin_user_id) references usuario (id)
            on update cascade on delete cascade,
    constraint user_task_assignments_interviewer_user_id_foreign
        foreign key (interviewer_user_id) references usuario (id)
            on update cascade on delete cascade,
    constraint user_task_assignments_task_type_id_foreign
        foreign key (task_type_id) references task_types (id)
            on update cascade on delete cascade,
    constraint user_task_assignments_user_id_foreign
        foreign key (user_id) references usuario (id)
            on update cascade on delete cascade
)
    comment 'Asignaciones de tareas/entrevistas a usuarios' engine = InnoDB
                                                            collate = utf8mb4_unicode_ci;

create table task_contact_attempts
(
    id             bigint unsigned auto_increment
        primary key,
    assignment_id  bigint unsigned                                             not null comment 'ID de la asignación',
    attempt_date   timestamp        default CURRENT_TIMESTAMP                  not null comment 'Fecha del intento',
    contact_method enum ('llamada', 'whatsapp', 'email', 'presencial', 'otro') null comment 'Método de contacto utilizado',
    was_successful tinyint unsigned default '0'                                not null comment 'Si se logró el contacto',
    notes          text                                                        null comment 'Observaciones del intento',
    created_at     timestamp                                                   null,
    updated_at     timestamp                                                   null,
    constraint task_contact_attempts_assignment_id_foreign
        foreign key (assignment_id) references user_task_assignments (id)
            on update cascade on delete cascade
)
    comment 'Registro de intentos de contacto para cada asignación' engine = InnoDB
                                                                    collate = utf8mb4_unicode_ci;

create index task_contact_attempts_assignment_id
    on task_contact_attempts (assignment_id);

create index user_task_assignments_admin_user_id
    on user_task_assignments (admin_user_id);

create index user_task_assignments_interviewer_user_id
    on user_task_assignments (interviewer_user_id);

create index user_task_assignments_status
    on user_task_assignments (status);

create index user_task_assignments_task_type_id
    on user_task_assignments (task_type_id);

create index user_task_assignments_user_id
    on user_task_assignments (user_id);

create table user_task_pool
(
    id               bigint unsigned auto_increment
        primary key,
    user_id          bigint unsigned                                                  not null comment 'Usuario en el pool',
    task_type_id     bigint unsigned                                                  not null comment 'Tipo de tarea para la cual está pre-clasificado',
    priority         tinyint unsigned                             default '5'         not null comment 'Prioridad: 1=Alta, 5=Normal, 10=Baja',
    added_by_user_id bigint unsigned                                                  not null comment 'Administrador que agregó al pool',
    owned_by_user_id bigint unsigned                                                  null comment 'Administrador dueño del pool (NULL = pool compartido)',
    is_shared        tinyint unsigned                             default '0'         not null comment 'Si es visible para todos los administradores',
    status           enum ('pendiente', 'asignado', 'descartado') default 'pendiente' not null comment 'Estado en el pool',
    notes            text                                                             null comment 'Notas de pre-clasificación',
    assigned_at      timestamp                                                        null comment 'Fecha cuando se asignó formalmente',
    created_at       timestamp                                                        null,
    updated_at       timestamp                                                        null,
    constraint user_task_pool_added_by_user_id_foreign
        foreign key (added_by_user_id) references usuario (id)
            on update cascade on delete cascade,
    constraint user_task_pool_owned_by_user_id_foreign
        foreign key (owned_by_user_id) references usuario (id)
            on update cascade on delete set null,
    constraint user_task_pool_task_type_id_foreign
        foreign key (task_type_id) references task_types (id)
            on update cascade on delete cascade,
    constraint user_task_pool_user_id_foreign
        foreign key (user_id) references usuario (id)
            on update cascade on delete cascade
)
    comment 'Pool de usuarios pre-clasificados para diferentes tipos de tareas. Soporta pools privados, compartidos y por administrador'
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index user_task_pool_added_by_user_id
    on user_task_pool (added_by_user_id);

create index user_task_pool_is_shared
    on user_task_pool (is_shared);

create index user_task_pool_owned_by_user_id
    on user_task_pool (owned_by_user_id);

create index user_task_pool_priority
    on user_task_pool (priority);

create index user_task_pool_status
    on user_task_pool (status);

create index user_task_pool_task_type_id
    on user_task_pool (task_type_id);

create index user_task_pool_user_id
    on user_task_pool (user_id);

create table user_updates
(
    id              bigint unsigned auto_increment
        primary key,
    user_id         bigint unsigned                     not null,
    last_updated_at timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint user_updates_user_id_foreign
        foreign key (user_id) references usuario (id)
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index usuario_1
    on usuario (id, dni);

create table usuario_asiste_agape
(
    id_usuario  bigint unsigned                                                              not null,
    id_evento   bigint unsigned                                                              not null,
    registro    enum ('LLEGO', 'NO LLEGA', 'CANCELA', 'ABANDONA') collate utf8mb3_spanish_ci not null,
    observacion varchar(150) collate utf8mb3_spanish_ci                                      null,
    created_at  timestamp                                                                    not null,
    updated_at  timestamp                                                                    not null,
    primary key (id_usuario, id_evento),
    constraint usuario_asiste_agape_ibfk_1
        foreign key (id_usuario) references usuario (id)
            on update cascade on delete cascade,
    constraint usuario_asiste_agape_ibfk_2
        foreign key (id_evento) references evento (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index id_evento
    on usuario_asiste_agape (id_evento);

create table usuario_formacion
(
    t_formacion int null,
    id          int not null
)
    comment 'Información relacionada con la formación academica' engine = InnoDB
                                                                 collate = utf8mb4_unicode_ci;

create table usuario_has_agapes
(
    id_usuario     bigint unsigned                         not null
        primary key,
    id_agape       bigint unsigned                         not null,
    convocados     varchar(100)                            not null,
    activo         tinyint(1) default 1                    not null,
    observacion    varchar(150) collate utf8mb3_spanish_ci null,
    profundizacion tinyint    default 0                    not null,
    grupo          varchar(150)                            null,
    created_at     timestamp                               null,
    updated_at     timestamp                               null,
    constraint fk_usuario_agape_agape
        foreign key (id_agape) references agapes (id)
            on update cascade on delete cascade,
    constraint fk_usuario_agape_usuario
        foreign key (id_usuario) references usuario (id)
            on update cascade on delete cascade
)
    comment 'Tabla que relaciona usuarios con ágapes y almacena información sobre su participación, representado en varios estados segun su nivel de participacion de acuerdo a las diferentes circuntancias, 1 Activo etc'
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index id_agape
    on usuario_has_agapes (id_agape);

create table usuario_has_users
(
    id_usuario bigint unsigned not null,
    id_users   bigint unsigned not null,
    created_at timestamp       not null,
    updated_at timestamp       not null,
    primary key (id_usuario, id_users),
    constraint usuario_has_users_ibfk_1
        foreign key (id_usuario) references usuario (id)
            on update cascade on delete cascade,
    constraint usuario_has_users_ibfk_2
        foreign key (id_users) references users (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb3_spanish_ci;

create index id_users
    on usuario_has_users (id_users);

create table whatsapp_chat_messages
(
    id                   bigint unsigned auto_increment
        primary key,
    id_usuario           bigint unsigned                                                                              not null comment 'ID del usuario de la conversación',
    wa_message_id        varchar(255)                                                                                 null comment 'ID del mensaje de WhatsApp',
    message_body         text                                                                                         not null comment 'Contenido del mensaje',
    media_type           enum ('text', 'image', 'button', 'interactive', 'document', 'audio', 'video') default 'text' not null comment 'Tipo de contenido del mensaje',
    direction            enum ('inbound', 'outbound')                                                                 not null comment 'Dirección: entrante o saliente',
    button_payload       varchar(100)                                                                                 null comment 'Payload del botón si es respuesta de Quick Reply',
    is_read              tinyint(1)                                                                    default 0      not null comment 'Si el mensaje fue leído por el operador',
    processed_by_user_id bigint unsigned                                                                              null comment 'ID del operador que procesó el mensaje',
    requires_attention   tinyint(1)                                                                    default 0      not null comment 'Si requiere atención de un asesor',
    created_at           timestamp                                                                                    null,
    updated_at           timestamp                                                                                    null,
    constraint whatsapp_chat_messages_id_usuario_foreign
        foreign key (id_usuario) references usuario (id)
            on update cascade on delete cascade,
    constraint whatsapp_chat_messages_processed_by_user_id_foreign
        foreign key (processed_by_user_id) references usuario (id)
            on update cascade on delete set null
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index whatsapp_chat_messages_direction_index
    on whatsapp_chat_messages (direction);

create index whatsapp_chat_messages_id_usuario_created_at_index
    on whatsapp_chat_messages (id_usuario, created_at);

create index whatsapp_chat_messages_id_usuario_index
    on whatsapp_chat_messages (id_usuario);

create index whatsapp_chat_messages_is_read_index
    on whatsapp_chat_messages (is_read);

create index whatsapp_chat_messages_requires_attention_index
    on whatsapp_chat_messages (requires_attention);

create index whatsapp_chat_messages_wa_message_id_index
    on whatsapp_chat_messages (wa_message_id);

create table whatsapp_notifications
(
    id                bigint unsigned auto_increment
        primary key,
    message_id        varchar(255)               not null comment 'ID único del mensaje de Meta WhatsApp',
    id_usuario        bigint unsigned            not null comment 'ID del usuario destinatario',
    phone             varchar(20)                not null comment 'Número de teléfono del destinatario',
    status            varchar(30) default 'sent' not null comment 'Estado: sent, delivered, read, failed',
    template_name     varchar(100)               not null comment 'Nombre del template de WhatsApp',
    template_params   json                       null comment 'Parámetros enviados al template',
    evento_id         bigint unsigned            null comment 'ID del evento relacionado',
    status_updated_at timestamp                  null comment 'Última actualización de status',
    created_at        timestamp                  null,
    updated_at        timestamp                  null,
    constraint whatsapp_notifications_message_id_unique
        unique (message_id),
    constraint whatsapp_notifications_evento_id_foreign
        foreign key (evento_id) references evento (id)
            on update cascade on delete set null,
    constraint whatsapp_notifications_id_usuario_foreign
        foreign key (id_usuario) references usuario (id)
            on update cascade on delete cascade
)
    engine = InnoDB
    collate = utf8mb4_unicode_ci;

create index whatsapp_notifications_evento_id_index
    on whatsapp_notifications (evento_id);

create index whatsapp_notifications_id_usuario_index
    on whatsapp_notifications (id_usuario);

create index whatsapp_notifications_message_id_index
    on whatsapp_notifications (message_id);

create index whatsapp_notifications_phone_index
    on whatsapp_notifications (phone);

create index whatsapp_notifications_status_index
    on whatsapp_notifications (status);


