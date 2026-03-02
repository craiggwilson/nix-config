# Java Testing

## JUnit 5 Basics

```java
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

class UserServiceTest {
    
    private UserService userService;
    
    @BeforeEach
    void setUp() {
        userService = new UserService(new MockUserRepository());
    }
    
    @Test
    @DisplayName("should create user with valid input")
    void createUser_validInput_returnsUser() {
        User user = userService.create("John", "john@example.com");
        
        assertNotNull(user.getId());
        assertEquals("John", user.getName());
    }
    
    @Test
    void createUser_invalidEmail_throwsException() {
        assertThrows(ValidationException.class, () -> 
            userService.create("John", "invalid-email")
        );
    }
}
```

## Parameterized Tests

```java
@ParameterizedTest
@CsvSource({
    "john@example.com, true",
    "invalid-email, false",
    "'', false"
})
void isValidEmail(String email, boolean expected) {
    assertEquals(expected, validator.isValidEmail(email));
}

@ParameterizedTest
@MethodSource("provideUsers")
void processUser(User user, String expectedResult) {
    assertEquals(expectedResult, service.process(user));
}

static Stream<Arguments> provideUsers() {
    return Stream.of(
        Arguments.of(new User("John"), "processed-John"),
        Arguments.of(new User("Jane"), "processed-Jane")
    );
}
```

## Mockito

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    
    @Mock
    private UserRepository userRepository;
    
    @InjectMocks
    private UserService userService;
    
    @Test
    void getUser_exists_returnsUser() {
        when(userRepository.findById(1L))
            .thenReturn(Optional.of(new User(1L, "John")));
        
        User user = userService.getUser(1L);
        
        assertEquals("John", user.getName());
        verify(userRepository).findById(1L);
    }
}
```

## Spring Boot Test

```java
@SpringBootTest
@AutoConfigureMockMvc
class UserControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    void getUser_returns200() throws Exception {
        mockMvc.perform(get("/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name").value("John"));
    }
}
```
