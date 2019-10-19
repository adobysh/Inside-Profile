//
//  SuggestedUserContainerWebData.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/16/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

protocol User: Codable {
    var id: String? { get }
    var full_name: String? { get }
    var username: String? { get }
    var profile_pic_url: String? { get }
    var is_verified: Bool? { get }
    var followers: Int? { get }
}

struct BaseUser: User {
    var id: String?
    var full_name: String?
    var username: String?
    var profile_pic_url: String?
    var is_verified: Bool?
    var followers: Int?
}

struct SuggestedUsersWebContainer: Codable {
    let data: SuggestedUsersWebContainerData?
    let status: String? // "ok"
}

struct SuggestedUsersWebContainerData: Codable {
    let user: SuggestedUsersWebContainerUser?
}

struct SuggestedUsersWebContainerUser: Codable {
//    let connected_fbid: String? // null
//    let edge_facebook_friends: ?
    let edge_suggested_users: EdgeSuggestedUsers?
}

struct EdgeSuggestedUsers: Codable {
    let page_info: SuggestedUsersPageInfo?
    let edges: [SuggestedUserContainer]?
}

struct SuggestedUsersPageInfo: Codable {
    let has_next_page: Bool?
}

struct SuggestedUserContainer: Codable {
    let node: SuggestedUserNode?
}

struct SuggestedUserNode: Codable {
    let user: GraphUser?
    let description: String? // Followed by lizaveta_glazina
}

struct GraphUser: User, Codable, Comparable {
    let edge_followed_by: EdgeFollowedBy?
    let followed_by_viewer: Bool?
    let full_name: String?
    let id: String?
    let is_private: Bool?
    let is_verified: Bool?
    let is_viewer: Bool?
    let profile_pic_url: String?
    let requested_by_viewer: Bool?
    let username: String?
    
    var followers: Int? {
        get {
            return edge_followed_by?.count
        }
    }
    
    static func ==(lhs: GraphUser, rhs: GraphUser) -> Bool {
        return lhs.username == rhs.username
    }
    
    static func < (lhs: GraphUser, rhs: GraphUser) -> Bool {
        return (lhs.full_name ?? "") < (rhs.full_name ?? "")
    }
}

struct EdgeFollowedBy: Codable {
    let count: Int?
}

//{
//    "data": {
//        "user": {
//            "connected_fbid": null,
//            "edge_facebook_friends": {
//                "count": 0
//            },
//            "edge_suggested_users": {
//                "page_info": {
//                    "has_next_page": true
//                },
//                "edges": [
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 849609
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Hideo Kojima",
//                                "id": "6937567427",
//                                "is_private": false,
//                                "is_verified": true,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/94285a484eae1227bb27b316724a5daf/5E26B679/t51.2885-19/s150x150/26870477_1663704427043880_2721194646276407296_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "hideo_kojima",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "6937567427",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 0,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "6937567427",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/94285a484eae1227bb27b316724a5daf/5E26B679/t51.2885-19/s150x150/26870477_1663704427043880_2721194646276407296_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "hideo_kojima"
//                                    }
//                                }
//                            },
//                            "description": "Followed by knowyourdemons + 1 more"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 539116
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Naughty Dog",
//                                "id": "1593309399",
//                                "is_private": false,
//                                "is_verified": true,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/e655f2de084d278102475bdedee7da8f/5E3F0B0B/t51.2885-19/s150x150/69429637_1005935663071049_5134368239677079552_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "naughty_dog_inc",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "1593309399",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 0,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "1593309399",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/e655f2de084d278102475bdedee7da8f/5E3F0B0B/t51.2885-19/s150x150/69429637_1005935663071049_5134368239677079552_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "naughty_dog_inc"
//                                    }
//                                }
//                            },
//                            "description": "Followed by knowyourdemons"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 65346
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Blaser",
//                                "id": "7183523384",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/d6896cee82c8ee3cfe6e1c6de386d0f4/5E22032B/t51.2885-19/s150x150/28157089_224612884619685_5054083249236606976_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "blaser_official",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "7183523384",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571205455,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "7183523384",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/d6896cee82c8ee3cfe6e1c6de386d0f4/5E22032B/t51.2885-19/s150x150/28157089_224612884619685_5054083249236606976_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "blaser_official"
//                                    }
//                                }
//                            },
//                            "description": "Followed by arsenus"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 66780
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Блог Гродно s13",
//                                "id": "2223733553",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/f02dc483b4fcd35e57dc5cb4978a41e0/5E26FF3F/t51.2885-19/s150x150/43817573_242539069761990_4126953793197703168_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "s13.ru",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "2223733553",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571233304,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "2223733553",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/f02dc483b4fcd35e57dc5cb4978a41e0/5E26FF3F/t51.2885-19/s150x150/43817573_242539069761990_4126953793197703168_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "s13.ru"
//                                    }
//                                }
//                            },
//                            "description": "Followed by dusk131313"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 3836
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Dilove",
//                                "id": "300710253",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/da9fa12fb9ffa0d4cb9bd2d9f03665c4/5E3FBAB1/t51.2885-19/s150x150/40598455_267534680545651_8917879555780247552_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "diloved",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "300710253",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571230558,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "300710253",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/da9fa12fb9ffa0d4cb9bd2d9f03665c4/5E3FBAB1/t51.2885-19/s150x150/40598455_267534680545651_8917879555780247552_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "diloved"
//                                    }
//                                }
//                            },
//                            "description": "Followed by knowyourdemons"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 2798
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Детский фотограф ГРОДНО",
//                                "id": "399043479",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/835ac3d51fb855fe7563de534bf5fd9f/5E3E7E45/t51.2885-19/s150x150/18948116_106177726614628_1674471843060252672_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "olga_gorchichko",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "399043479",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571204715,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "399043479",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/835ac3d51fb855fe7563de534bf5fd9f/5E3E7E45/t51.2885-19/s150x150/18948116_106177726614628_1674471843060252672_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "olga_gorchichko"
//                                    }
//                                }
//                            },
//                            "description": "Followed by dusk131313 + 2 more"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 104984
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Охота в России 🇷🇺",
//                                "id": "2098428886",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/d6abe56cfb855b89a98dc3287738f7e0/5E288194/t51.2885-19/s150x150/15251826_370883163261288_4775197506445246464_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "hunting_in_russia_official",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "2098428886",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571226983,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "2098428886",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/d6abe56cfb855b89a98dc3287738f7e0/5E288194/t51.2885-19/s150x150/15251826_370883163261288_4775197506445246464_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "hunting_in_russia_official"
//                                    }
//                                }
//                            },
//                            "description": "Followed by arsenus"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 100319
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "SWAROVSKI OPTIK Hunting",
//                                "id": "1189513024",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/5149a887af45d1ffab5db2deee0e11d2/5E64CE1B/t51.2885-19/s150x150/19954865_296744550790133_9187669279393185792_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "swarovskioptik_hunting",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "1189513024",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 0,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "1189513024",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/5149a887af45d1ffab5db2deee0e11d2/5E64CE1B/t51.2885-19/s150x150/19954865_296744550790133_9187669279393185792_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "swarovskioptik_hunting"
//                                    }
//                                }
//                            },
//                            "description": "Followed by arsenus"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 32443
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Лофт мебель для дома и бизнеса",
//                                "id": "4373405222",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/4d095e8a6a74d197ca12786a2bc07598/5E443911/t51.2885-19/s150x150/20901987_111793529490929_822778462463852544_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "loftovik",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "4373405222",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571235828,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "4373405222",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/4d095e8a6a74d197ca12786a2bc07598/5E443911/t51.2885-19/s150x150/20901987_111793529490929_822778462463852544_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "loftovik"
//                                    }
//                                }
//                            },
//                            "description": "Followed by dekorativnaishtukaturka"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 108039
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "ENGLBAK",
//                                "id": "5648235111",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/3dbee0678caaacf996d6f483e4250523/5E30CCA7/t51.2885-19/s150x150/56692407_1524407044383549_2694697446839156736_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "englbak",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "5648235111",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571232168,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "5648235111",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/3dbee0678caaacf996d6f483e4250523/5E30CCA7/t51.2885-19/s150x150/56692407_1524407044383549_2694697446839156736_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "englbak"
//                                    }
//                                }
//                            },
//                            "description": "Followed by tovstikt"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 16930
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "электромонтаж минск",
//                                "id": "5829115250",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/c005ae91517015abad2ae01dfe646881/5E4435EC/t51.2885-19/s150x150/44196083_327443481377772_5278883813194203136_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "sviatlo.by",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "5829115250",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571213782,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "5829115250",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/c005ae91517015abad2ae01dfe646881/5E4435EC/t51.2885-19/s150x150/44196083_327443481377772_5278883813194203136_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "sviatlo.by"
//                                    }
//                                }
//                            },
//                            "description": "Followed by sgorchichko"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 86045
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Black Design Journal №1 🔵",
//                                "id": "3916126404",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/092ff7a0841e7b914f33465384f56c16/5E23A2AA/t51.2885-19/s150x150/51411297_465313144005187_1327783182438760448_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "black_design_journal",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "3916126404",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571201369,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "3916126404",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/092ff7a0841e7b914f33465384f56c16/5E23A2AA/t51.2885-19/s150x150/51411297_465313144005187_1327783182438760448_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "black_design_journal"
//                                    }
//                                }
//                            },
//                            "description": "Followed by re.flex.ion"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 1544
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "ООО Спецевротулс",
//                                "id": "7313455673",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/6c3731074b8218dec3d475a61706b9fd/5E363F50/t51.2885-19/s150x150/29090047_202791587159878_4923686740754956288_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "eurotools.by",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "7313455673",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 0,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "7313455673",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/6c3731074b8218dec3d475a61706b9fd/5E363F50/t51.2885-19/s150x150/29090047_202791587159878_4923686740754956288_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "eurotools.by"
//                                    }
//                                }
//                            },
//                            "description": "Followed by sgorchichko"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 9220
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "КНИЖНАЯ НОРА",
//                                "id": "3100623373",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/2f0623b778cfbf4f056f37ccd5e5d500/5E28F4A7/t51.2885-19/s150x150/12965055_1706732346282064_143113642_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "bookhole_by",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "3100623373",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571231510,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "3100623373",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/2f0623b778cfbf4f056f37ccd5e5d500/5E28F4A7/t51.2885-19/s150x150/12965055_1706732346282064_143113642_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "bookhole_by"
//                                    }
//                                }
//                            },
//                            "description": "Followed by vallmond"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 1141
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Kirill Skorynin",
//                                "id": "4589019",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/a3fa577fc1aa19f84d23638d61d2e52f/5E2A5425/t51.2885-19/11848977_1460391910931068_495388300_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "pixel_rock",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "4589019",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 0,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "4589019",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/a3fa577fc1aa19f84d23638d61d2e52f/5E2A5425/t51.2885-19/11848977_1460391910931068_495388300_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "pixel_rock"
//                                    }
//                                }
//                            },
//                            "description": "Followed by re.flex.ion"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 68545
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Murder Apparel",
//                                "id": "8671254992",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/1de70e38b7e6fd702f06a25eef3f38a1/5E300760/t51.2885-19/s150x150/43985547_2397236716969862_4911571913618227200_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "murderapparel",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "8671254992",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571229843,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "8671254992",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/1de70e38b7e6fd702f06a25eef3f38a1/5E300760/t51.2885-19/s150x150/43985547_2397236716969862_4911571913618227200_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "murderapparel"
//                                    }
//                                }
//                            },
//                            "description": "Followed by dusk131313"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 70740
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "▪️ДИЗАЙН ИНТЕРЬЕРА РБ И РФ",
//                                "id": "2615239165",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/4e2154b4b0a5090b757cbb4ff4e52bdd/5E1E68E4/t51.2885-19/s150x150/51569651_431641467573444_1819536850268717056_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "studio57.by",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "2615239165",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571224627,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "2615239165",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/4e2154b4b0a5090b757cbb4ff4e52bdd/5E1E68E4/t51.2885-19/s150x150/51569651_431641467573444_1819536850268717056_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "studio57.by"
//                                    }
//                                }
//                            },
//                            "description": "Followed by dusk131313"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 1078
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Ivan Smolyar",
//                                "id": "1576127502",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/42ac9ced91d681953203ef48c1c95b28/5E2E3B64/t51.2885-19/s150x150/69277453_674575576395344_156978228580319232_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "johnny_cosmic",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "1576127502",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 0,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "1576127502",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/42ac9ced91d681953203ef48c1c95b28/5E2E3B64/t51.2885-19/s150x150/69277453_674575576395344_156978228580319232_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "johnny_cosmic"
//                                    }
//                                }
//                            },
//                            "description": "Followed by re.flex.ion + 2 more"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 116110
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Группа \"Руки Вверх!\"",
//                                "id": "1140802971",
//                                "is_private": false,
//                                "is_verified": true,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/3fd8c31607d4f35a77a36ebd23831d4e/5E27F1E1/t51.2885-19/s150x150/70523044_2955247478033166_8220142993055678464_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "rukivverh_official",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "1140802971",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 0,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "1140802971",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/3fd8c31607d4f35a77a36ebd23831d4e/5E27F1E1/t51.2885-19/s150x150/70523044_2955247478033166_8220142993055678464_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "rukivverh_official"
//                                    }
//                                }
//                            },
//                            "description": "Popular"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 945303
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Английский для ленивых.",
//                                "id": "1552960764",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/b81cc9476529fdfbc8200998a2778b91/5E3333B0/t51.2885-19/s150x150/18888874_683886025131892_3132810177187676160_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "lazy_english",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "1552960764",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 0,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "1552960764",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/b81cc9476529fdfbc8200998a2778b91/5E3333B0/t51.2885-19/s150x150/18888874_683886025131892_3132810177187676160_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "lazy_english"
//                                    }
//                                }
//                            },
//                            "description": "Followed by sgorchichko + 1 more"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 616481
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Хорошая девочка Катя))",
//                                "id": "280513156",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/a0fe551252bf9df08ac80f4d66ac2b8e/5E4076D3/t51.2885-19/s150x150/45563929_215260719371459_7149160934651461632_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "katekirienko",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "280513156",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571227882,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "280513156",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/a0fe551252bf9df08ac80f4d66ac2b8e/5E4076D3/t51.2885-19/s150x150/45563929_215260719371459_7149160934651461632_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "katekirienko"
//                                    }
//                                }
//                            },
//                            "description": "Followed by knowyourdemons"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 34692508
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "National Geographic Travel",
//                                "id": "23947096",
//                                "is_private": false,
//                                "is_verified": true,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/69720205b371f9e79c5ff7e58cbcd0e0/5E44F739/t51.2885-19/s150x150/12132724_850743081710560_180824582_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "natgeotravel",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "23947096",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571236578,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "23947096",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/69720205b371f9e79c5ff7e58cbcd0e0/5E44F739/t51.2885-19/s150x150/12132724_850743081710560_180824582_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "natgeotravel"
//                                    }
//                                }
//                            },
//                            "description": "Followed by dusk131313"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 113780
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Английский легко и просто",
//                                "id": "4796361407",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/b358cc08feffc6fb0ff5250c38526365/5E2DF613/t51.2885-19/s150x150/25035930_1993976400873885_8028740103381712896_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "words.eng",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "4796361407",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 0,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "4796361407",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/b358cc08feffc6fb0ff5250c38526365/5E2DF613/t51.2885-19/s150x150/25035930_1993976400873885_8028740103381712896_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "words.eng"
//                                    }
//                                }
//                            },
//                            "description": "Followed by tovstikt"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 124686430
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "National Geographic",
//                                "id": "787132",
//                                "is_private": false,
//                                "is_verified": true,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/7a5e3635fdf72240c1a539491476733e/5E605BE8/t51.2885-19/s150x150/13597791_261499887553333_1855531912_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "natgeo",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "787132",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571158248,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "787132",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/7a5e3635fdf72240c1a539491476733e/5E605BE8/t51.2885-19/s150x150/13597791_261499887553333_1855531912_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "natgeo"
//                                    }
//                                }
//                            },
//                            "description": "Followed by dusk131313 + 1 more"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 399782
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "ЧП Беларусь 🇧🇾",
//                                "id": "5403734515",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/6547b13ad14cda10919e075237b68f2a/5E2E5B03/t51.2885-19/s150x150/40386531_317635425460864_1756534791047479296_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "cpbelarus",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "5403734515",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571219675,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "5403734515",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/6547b13ad14cda10919e075237b68f2a/5E2E5B03/t51.2885-19/s150x150/40386531_317635425460864_1756534791047479296_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "cpbelarus"
//                                    }
//                                }
//                            },
//                            "description": "Popular"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 68858
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Белье Ручной Работы",
//                                "id": "255585760",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/8bb5751639be5ef0daa82a0398e1bf70/5E43BC79/t51.2885-19/11190064_1446146552344974_905513786_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "miss_tic_lingerie_ua",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "255585760",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571223309,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "255585760",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/8bb5751639be5ef0daa82a0398e1bf70/5E43BC79/t51.2885-19/11190064_1446146552344974_905513786_a.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "miss_tic_lingerie_ua"
//                                    }
//                                }
//                            },
//                            "description": "Followed by knowyourdemons"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 1079
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Jay Jideliov",
//                                "id": "9484247",
//                                "is_private": true,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/94d3fcd308c27473db8131b120421810/5E62A5E7/t51.2885-19/s150x150/60118563_447068902718119_9076916795977236480_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "jideliov",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "9484247",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": null,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "9484247",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/94d3fcd308c27473db8131b120421810/5E62A5E7/t51.2885-19/s150x150/60118563_447068902718119_9076916795977236480_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "jideliov"
//                                    }
//                                }
//                            },
//                            "description": "Followed by re.flex.ion"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 3433
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "LILIYA✨BUSKO",
//                                "id": "402041596",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/3beced06d406318092e4a3cf1c932a3c/5E31BF6F/t51.2885-19/s150x150/68785887_3095327400539442_2422861197079478272_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "liliya_busko",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "402041596",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 0,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "402041596",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/3beced06d406318092e4a3cf1c932a3c/5E31BF6F/t51.2885-19/s150x150/68785887_3095327400539442_2422861197079478272_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "liliya_busko"
//                                    }
//                                }
//                            },
//                            "description": "Followed by arsenus"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 301197
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "ДИЗАЙН ИНТЕРЬЕРА 🔵",
//                                "id": "4326300713",
//                                "is_private": false,
//                                "is_verified": false,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/386be834583de79d4ff5769e8ea1cd14/5E424FBF/t51.2885-19/s150x150/35000713_1058445997655097_578084009423142912_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "loftdesignru",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "4326300713",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571174713,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "4326300713",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/386be834583de79d4ff5769e8ea1cd14/5E424FBF/t51.2885-19/s150x150/35000713_1058445997655097_578084009423142912_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "loftdesignru"
//                                    }
//                                }
//                            },
//                            "description": "Followed by re.flex.ion"
//                        }
//                    },
//                    {
//                        "node": {
//                            "user": {
//                                "edge_followed_by": {
//                                    "count": 1024010
//                                },
//                                "followed_by_viewer": false,
//                                "full_name": "Goodtype | Strength In Letters",
//                                "id": "478987666",
//                                "is_private": false,
//                                "is_verified": true,
//                                "is_viewer": false,
//                                "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/f734c608ad39b63c309ac10707f9eaac/5E2A0EB4/t51.2885-19/s150x150/65226523_487385818678035_6635163652670357504_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                "requested_by_viewer": false,
//                                "username": "goodtype",
//                                "edge_owner_to_timeline_media": {
//                                    "edges": []
//                                },
//                                "reel": {
//                                    "id": "478987666",
//                                    "expiring_at": 1571323409,
//                                    "has_pride_media": false,
//                                    "latest_reel_media": 1571231818,
//                                    "seen": null,
//                                    "owner": {
//                                        "__typename": "GraphUser",
//                                        "id": "478987666",
//                                        "profile_pic_url": "https://instagram.fmsq1-1.fna.fbcdn.net/vp/f734c608ad39b63c309ac10707f9eaac/5E2A0EB4/t51.2885-19/s150x150/65226523_487385818678035_6635163652670357504_n.jpg?_nc_ht=instagram.fmsq1-1.fna.fbcdn.net",
//                                        "username": "goodtype"
//                                    }
//                                }
//                            },
//                            "description": "Followed by re.flex.ion"
//                        }
//                    }
//                ]
//            }
//        }
//    },
//    "status": "ok"
//}
