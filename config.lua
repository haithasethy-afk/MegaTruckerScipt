Config = {
    JobName = 'TruckerJob',

    InteractionKey = 38,

    NPC = {
        model = 's_m_m_trucker_01',

        coords = vector4(
            1226.1221,
            -3204.8772,
            6.0280,
            177.5642
        ),

        interactDistance = 3.0
    },

    Hauler = {
        model = 'actros',

        coords = vector4(
            1222.9777,
            -3218.4448,
            6.0524,
            91.2739
        )
    },

    Trailer = {
        model = 'trailers',

        coords = vector4(
            1193.0276,
            -3200.7493,
            7.6195,
            180.6632
        )
    },

    Blips = {
        depot = {
            sprite = 477,
            color = 5,
            scale = 0.8,
            name = 'Trucking Depot'
        },

        trailer = {
            sprite = 479,
            color = 5,
            scale = 0.75,
            name = 'Assigned Trailer'
        }
    }
}