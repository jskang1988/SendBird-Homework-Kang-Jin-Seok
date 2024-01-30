# SendBird-Homework-Kang-Jin-Seok
구현 내용

- 사용된 3rd party
    1) Alamofire

- 과제 완성도
    1) SBUserManager, SBNetworkClient, SBUserStorage, Request를 구현하였으며, 제시된 Protocol을 모두 준수하였습니다.
    2) 과제에 대한 기본 요구사항에 대해 진행률은 100%입니다.

- Rate Limit 처리
    1) Sliding Window Log와 같진 않지만 유사한 방식으로 Rate Limit을 구현하여 1req/sec 이상의 요청이 들어가지 않도록 제어했습니다.
    2) 마지막 요청 수행 시간 이후로 1초가 지나지 않은 상태라면, 해당 요청은 queue에 들어가고, 마지막 요청 수행 시간 + 1초에 실행이 예약됩니다.
    3) 마지막 요청 수행 시간 이후로 1초가 지난 상태라면, 해당 요청은 queue에 들어가고 즉시 실행됩니다.
    4) 요청이 queue에 들어간 뒤 마지막 요청 수행 시간을 갱신합니다.
    5) 만약 큐에 현재 진행 중인 요청을 포함하여 10개 이상의 요청이 쌓여있는 상태라면, 추가로 들어온 요청은 수행되지 않고 Rate Limit Error를 반환합니다.

- Error 처리
    1) 통합된 에러 타입을 정의하였습니다. (SBError)
    2) SendBird 서버 실패 응답인 경우, 서버에서 내려온 code, message를 반환합니다.
    3) SDK 내부에서 검출된 에러인 경우, 최대한 자세한 사항을 포함하여 message를 반환했습니다.

- Thread Safe 처리
    1) SDK는 스레드 안전하지 않은 방식으로 사용될 수 있으므로, SBUserStorage는 Thread Safe 할 수 있는 형태로 구현되었습니다.
 
- Memory Leak 관련
    1) 클로저 사용부에 weak self 키워드(약한 참조)를 Memory Leak이 발생하지 않도록 대비했습니다.
 
- XCTest 수행 관련
    1) 제시된 테스트 케이스를 모두 수행했으며 통과를 확인했습니다.
    2) 다만 테스트 케이스 자체가 잘못 작성된 것처럼 보이는 부분도 확인했습니다.
    3) testInitApplicationWithDifferentAppIdClearsData에서 createUser 호출 후 SDK에서 완료 콜백이 도착하기 전에, userStorage의 저장된 유저 수는 0이 됩니다.
    4) 과제 요구사항 문서에, 'createUser는 생성 요청이 성공한 뒤에 캐시에 추가되어야 합니다'라는 항목이 있기 때문입니다.
    5) 이는 실무에서는 테스트 케이스에도 오류가 있을 수 있으며, 이를 확인해 보라는 과제의 의도라고 보여집니다.
 
감사합니다!
