//
//  ImageSearchClient.swift
//  NavigationCookbook
//
//  Created by YangJoonHyeok on 6/8/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import ComposableArchitecture
import Foundation

@DependencyClient
public struct ImageSearchClient {
	public var getImage: @Sendable (_ query: String) async throws -> String
}

extension ImageSearchClient: DependencyKey {
	public static var liveValue: ImageSearchClient {
		return ImageSearchClient(
			getImage: { query in
				guard let percentEncodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
					throw NSError(domain: "EncodingError", code: -1, userInfo: nil)
				}
				var urlReqeust = URLRequest(url: URL(string: "https://dapi.kakao.com/v2/search/image?query=\(percentEncodedQuery)")!)
				urlReqeust.httpMethod = "GET"
				urlReqeust.allHTTPHeaderFields = [
					"Authorization": "KakaoAK 5363ff2aa13b9956ace377d6a6b06857"
				]
        let (data, _) = try await URLSession.shared.data(for: urlReqeust)
				guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
							let jsonDict = jsonObject as? [String: Any],
							let documents = jsonDict["documents"] as? [[String: Any]],
							let firstDocument = documents.first,
							let imageUrl = firstDocument["image_url"] as? String else {
					throw NSError(domain: "ParsingError", code: -1, userInfo: nil)
				}
				return imageUrl
			}
		)
	}
	
  public static var previewValue: ImageSearchClient {
    return ImageSearchClient { query in
      if query == "에스파" {
        return "https://i.namu.wiki/i/BDPU125fdYpP6zhAegn7OoFNc_HyboZ5RlkZ422Iic8AA30DMDcnXqtVuruEYRdIGbz1d-FdWMEIAN1LMh0P7xtGinKDZJw-tonXy6RK85P1WiNjLGpHbyReMtlv4UD6LxFsttQ1VpVSjRpcrejXtw.webp"
      } else if query == "카리나" {
        return "https://pds.joongang.co.kr/news/component/htmlphoto_mmdata/202403/09/21e88381-7867-410a-b0c3-5d6c9cd430b1.jpg"
      } else if query == "윈터" {
        return "https://newsimg.sedaily.com/2024/02/18/2D5EQYC0HG_1.jpg"
      } else if query == "닝닝" {
        return "https://orgthumb.mt.co.kr/06/2023/03/2023031615153210777_1.jpg"
      } else if query == "지젤" {
        return "https://talkimg.imbc.com/TVianUpload/tvian/TViews/image/2023/06/07/a14fbc5e-6e2e-46b8-8d8f-60ead5b2d766.jpg"
      } else {
        return "https://cdn.discordapp.com/attachments/1147011195086307399/1249689866455748679/Untitled.jpg?ex=666837e2&is=6666e662&hm=68ac565e2e88d4735281ce89929a6dd8096e6b455e0c110eeda228e0cdd35d2e&"
      }
    }
  }
  
	public static var testValue: ImageSearchClient {
		return ImageSearchClient()
	}
}

extension DependencyValues {
	public var imageSearchClient: ImageSearchClient {
		get { self[ImageSearchClient.self] }
		set { self[ImageSearchClient.self] = newValue }
	}
}
