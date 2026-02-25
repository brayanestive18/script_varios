create table _prisma_migrations
(
    id                  varchar(36)                            not null
        primary key,
    checksum            varchar(64)                            not null,
    finished_at         timestamp with time zone,
    migration_name      varchar(255)                           not null,
    logs                text,
    rolled_back_at      timestamp with time zone,
    started_at          timestamp with time zone default now() not null,
    applied_steps_count integer                  default 0     not null
);

alter table _prisma_migrations
    owner to postgres;

create table roles
(
    id          serial
        primary key,
    uuid        text                                   not null,
    name        text                                   not null,
    description text,
    "default"   boolean      default false             not null,
    created_at  timestamp(3) default CURRENT_TIMESTAMP not null,
    updated_at  timestamp(3)                           not null,
    deleted_at  timestamp(3)
);

alter table roles
    owner to postgres;

create unique index roles_uuid_key
    on roles (uuid);

create index roles_name_idx
    on roles (name);

create table users
(
    id                serial
        primary key,
    uuid              text                                   not null,
    provider_auth_id  text                                   not null,
    email             text                                   not null,
    status            text         default 'ACTIVE'::text    not null,
    is_email_verified boolean,
    is_provider       text,
    is_social         boolean,
    created_at        timestamp(3) default CURRENT_TIMESTAMP not null,
    updated_at        timestamp(3)                           not null,
    deleted_at        timestamp(3)
);

alter table users
    owner to postgres;

create unique index users_uuid_key
    on users (uuid);

create unique index users_provider_auth_id_key
    on users (provider_auth_id);

create index users_provider_auth_id_idx
    on users (provider_auth_id);

create table user_roles
(
    id         serial
        primary key,
    user_id    integer                                not null
        references users
            on update cascade on delete cascade,
    role_id    integer                                not null
        references roles
            on update cascade on delete cascade,
    created_at timestamp(3) default CURRENT_TIMESTAMP not null
);

alter table user_roles
    owner to postgres;

create index user_roles_user_id_idx
    on user_roles (user_id);

create index user_roles_role_id_idx
    on user_roles (role_id);

create unique index user_roles_user_id_role_id_uk
    on user_roles (user_id, role_id);

create table profiles
(
    id               serial
        primary key,
    uuid             text                                   not null,
    user_id          integer                                not null
        references users
            on update cascade on delete restrict,
    dni              text,
    first_name       text                                   not null,
    middle_name      text,
    last_name        text                                   not null,
    second_last_name text,
    gender           text,
    birth_date       timestamp(3),
    phone            text,
    mobile           text,
    avatar_url       text,
    created_at       timestamp(3) default CURRENT_TIMESTAMP not null,
    updated_at       timestamp(3)                           not null,
    deleted_at       timestamp(3)
);

alter table profiles
    owner to postgres;

create unique index profiles_uuid_key
    on profiles (uuid);

create unique index profiles_user_id_key
    on profiles (user_id);

create unique index profiles_dni_key
    on profiles (dni);

create index profiles_user_id_idx
    on profiles (user_id);

create index profiles_dni_idx
    on profiles (dni);

create table profile_dni
(
    id              serial
        primary key,
    uuid            text                                   not null,
    profile_id      integer                                not null
        references profiles
            on update cascade on delete cascade,
    "dniType"       text                                   not null,
    expedition_date timestamp(3),
    birthdate       timestamp(3),
    is_current      boolean                                not null,
    created_at      timestamp(3) default CURRENT_TIMESTAMP not null,
    updated_at      timestamp(3)                           not null,
    deleted_at      timestamp(3)
);

alter table profile_dni
    owner to postgres;

create unique index profile_dni_uuid_key
    on profile_dni (uuid);

create index profile_dni_profile_id_idx
    on profile_dni (profile_id);

create table profile_addresses
(
    id           serial
        primary key,
    uuid         text                                   not null,
    profile_id   integer                                not null
        references profiles
            on update cascade on delete cascade,
    country      text,
    state        text,
    city         text,
    "adressType" text         default 'HOME'::text      not null,
    is_primary   boolean      default false             not null,
    address_line text,
    neighborhood text,
    created_at   timestamp(3) default CURRENT_TIMESTAMP not null,
    updated_at   timestamp(3)                           not null,
    deleted_at   timestamp(3)
);

alter table profile_addresses
    owner to postgres;

create unique index profile_addresses_uuid_key
    on profile_addresses (uuid);

create index profile_addresses_profile_id_idx
    on profile_addresses (profile_id);

create index profile_addresses_primary_idx
    on profile_addresses (profile_id, is_primary);

create table profile_employment
(
    id            serial
        primary key,
    uuid          text                                   not null,
    profile_id    integer                                not null
        references profiles
            on update cascade on delete cascade,
    occupation    text,
    company_name  text,
    company_phone text,
    start_date    timestamp(3),
    end_date      timestamp(3),
    created_at    timestamp(3) default CURRENT_TIMESTAMP not null,
    updated_at    timestamp(3)                           not null,
    deleted_at    timestamp(3)
);

alter table profile_employment
    owner to postgres;

create unique index profile_employment_uuid_key
    on profile_employment (uuid);

create index profile_employment_profile_id_idx
    on profile_employment (profile_id);

create table profile_family
(
    id             serial
        primary key,
    uuid           text                                   not null,
    profile_id     integer                                not null
        references profiles
            on update cascade on delete cascade,
    marital_status text,
    children_count integer,
    created_at     timestamp(3) default CURRENT_TIMESTAMP not null,
    updated_at     timestamp(3)                           not null,
    deleted_at     timestamp(3)
);

alter table profile_family
    owner to postgres;

create unique index profile_family_uuid_key
    on profile_family (uuid);

create unique index profile_family_profile_id_key
    on profile_family (profile_id);


