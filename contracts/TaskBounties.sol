// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

// @author Skillsbite
// @title Task Bounties
contract TaskBounties {

    //-------------------------- EVENTS --------------------------

    // User Events

    event UserRegistered(
        address _user,
        uint256 timeInfo
    );

    event UserDeleted(
        address _user,
        uint256 timeInfo
    );

    event UserSuspended(
        address _user,
        uint256 timeInfo
    );

    event UserUnsuspended(
        address _user,
        uint256 timeInfo
    );

    event UserAttemptedTask(
        address _user,
        address _educator,
        uint256 _learningPathId,
        uint256 _taskId,
        uint256 timeInfo
    );

    // Educator Events

    event EducatorAdded(
        address _educator,
        uint256 timeInfo
    );

    event EducatorDeleted(
        address _educator,
        uint256 timeInfo
    );

    event VerifyTaskAttempt(
        address _user,
        uint256 _learningPathId,
        uint256 _taskId,
        uint256 _xpEarned,
        address _educator,
        uint256 timeInfo
    );

    event RejectTaskAttempt(
        address _user,
        uint256 _learningPathId,
        uint256 _taskId,
        address _educator,
        uint256 timeInfo
    );

    // Task Events

    event TaskCreated(
        address _educator,
        uint256 _learningPathId,
        uint256 _taskId,
        uint256 timeInfo
    );

    // Learning Path Events

    event LearningPathCreated(
        address _educator,
        uint256 _id,
        uint256 timeInfo
    );

    event LearningPathActivated(
        address _educator,
        uint256 _id,
        uint256 timeInfo
    );

    event LearningPathInactivated(
        address _educator,
        uint256 _id,
        uint256 timeInfo
    );

    // Admin Events

    event AdminActivatedPath(
        address _educator,
        uint256 _id,
        uint256 timeInfo
    );

    event AdminInctivatedPath(
        address _educator,
        uint256 _id,
        uint256 timeInfo
    );

    event AdminVerifyTaskAttempt(
        address _user,
        uint256 _learningPathId,
        uint256 _taskId,
        uint256 _xpEarned,
        address _educator,
        uint256 timeInfo
    );

    event AdminRejectTaskAttempt(
        address _user,
        uint256 _learningPathId,
        uint256 _taskId,
        address _educator,
        uint256 timeInfo
    );

    event AdminEditedXp(
        address _user,
        uint256 _xp,
        uint256 timeInfo
    );

    //-------------------------- VARIABLES --------------------------

    address public owner;

    // User Variables

    struct User {
        uint256 xp;
        uint256 level;
        bool isSuspended;
        mapping(address => mapping(uint => mapping(uint => UserTaskStatus))) attemptedTasks;
    }

    enum UserTaskStatus{NotAttempted, InProgress, Rejected, Verified}

    mapping(address => User) public user;
    mapping(address => bool) public _isUser;
    mapping(address => bool) public deletedUser;
    address[] public userList;

    // Educator Variables

    struct Educator {
        string name;
        string communityName;
    }

    mapping(address => Educator) public educator;
    mapping(address => bool) public _isEducator;
    mapping(address => bool) public deletedEducator;
    mapping(string => bool) public onlyOneEducator;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) _onceVerified;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) _onceRejected;

    // Task Variables

    struct Task {
        uint256 xp;
        string name;
        string[] tags;
        uint256 deadline;
        uint256 numberOfWinners;
        address[] attemptedUsers;
        address[] winnerUsers;
    }

    // Learning Path Variables

    struct LearningPath {
        string name;
        LearningPathStatus status;
        Task[] task;
    }

    enum LearningPathStatus {Inactive, Active, Draft}

    mapping(address => LearningPath[]) public learningPath;

    constructor() {
        owner = msg.sender;
        _isEducator[owner] = true;
    }

    //-------------------------- MODIFIERS --------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner reserved only");
        _;
    }

    // User Modifiers

    modifier isUser(address _user) {
        require(_isUser[_user], "The user couldn't found!");
        _;
    }

    modifier isUserSuspended(address _user) {
        require(!(user[_user].isSuspended), "The user suspended");
        _;
    }

    // Educator Modifiers

    modifier isEducator(address _educator) {
        require(_isEducator[_educator], "You're not educator!");
        _;
    }

    modifier onceVerified(
        address _educator,
        uint256 _learningPathId,
        uint256 _taskId
    )
    {
        require(
            !(_onceVerified[_educator][_learningPathId][_taskId]),
            "Task verified by educator before"
        );
        _;
    }

    modifier onceRejected(
        address _educator,
        uint256 _learningPathId,
        uint256 _taskId
    )
    {
        require(
            !(_onceRejected[_educator][_learningPathId][_taskId]),
            "Task rejected by educator before"
        );
        _;
    }

    // Task Modifiers

    modifier userAttempted(
        address _user, 
        address _educator, 
        uint256 _learningPathId,
        uint256 _taskId
    ){
        require(
            user[_user].attemptedTasks[_educator][_learningPathId][_taskId] == UserTaskStatus.InProgress, 
            "User didn't attempted this task"
        );
        _;
    }

    modifier deadlinePassed(
        address _educator, 
        uint256 _learningPathId,
        uint256 _taskId
    ){
        require(
            learningPath[_educator][_learningPathId].task[_taskId].deadline > 
            block.timestamp, 
            "Task deadline passed"
        );
        _;
    }

    modifier numberOfWinnersFull(
        address _educator, 
        uint256 _learningPathId,
        uint256 _taskId
    ){
        require(
            learningPath[_educator][_learningPathId].task[_taskId].numberOfWinners > 
            learningPath[_educator][_learningPathId].task[_taskId].winnerUsers.length, 
            "The number of winners has been reached."
        );
        _;
    }

    // Learning Path Functions


    modifier learningPathAvailable(address _educator, uint256 _id){
        require(
            learningPath[_educator][_id].status == LearningPathStatus.Active, 
            "The learning path couldn't found"
        );
        _;
    }

    modifier pathReadyToActivate(address _educator, uint256 _id){
        require(
            (learningPath[_educator][_id].status == LearningPathStatus.Draft) || 
            (learningPath[_educator][_id].status == LearningPathStatus.Inactive), 
            "The learning path is not ready to publish "
        );
        _;
    }

    //-------------------------- FUNCTIONS --------------------------

    // User Functions

    function registerUser() external {
        require( 
            !( _isUser[msg.sender] ), 
            "The user already registered!" 
        );
        require( 
            !( deletedUser[msg.sender] ), 
            "The user's account has been deleted!" 
        );

        _isUser[msg.sender] = true;

        User storage newUser = user[msg.sender];
        newUser.level = 1;

        userList.push(msg.sender);

        emit UserRegistered(msg.sender, block.timestamp);
    }

    function attemptTask(
        address _educator, 
        uint256 _learningPathId,
        uint256 _taskId
    ) 
        external 
        isUser(msg.sender) 
        learningPathAvailable(_educator, _learningPathId)
        deadlinePassed(_educator, _learningPathId, _taskId)
    {
        user[msg.sender].attemptedTasks[_educator][_learningPathId][_taskId] = UserTaskStatus.InProgress;
        learningPath[_educator][_learningPathId].task[_taskId].attemptedUsers.push(msg.sender);

        emit UserAttemptedTask(
            msg.sender, 
            _educator, 
            _learningPathId,
            _taskId, 
            block.timestamp
        );
    }

    function getAttemptedTaskStatus(
        address _user, 
        address _educator, 
        uint256 _learningPathId,
        uint256 _taskId
    ) 
        external 
        isUser(_user)
        learningPathAvailable(_educator, _learningPathId)
        userAttempted(_user, _educator, _learningPathId, _taskId) 
        view 
        returns(UserTaskStatus) 
    {
        return user[_user].attemptedTasks[_educator][_learningPathId][_taskId];
    }

    function getUserList() external onlyOwner view returns(address[] memory) {
        return userList;
    }

    // Educator Functions

    function verifyTask(
        address _user, 
        uint256 _learningPathId,
        uint256 _taskId
    ) 
        external 
        isEducator(msg.sender)
        isUser(_user)
        isUserSuspended(_user)
        learningPathAvailable(msg.sender, _learningPathId)
        userAttempted(_user, msg.sender, _learningPathId, _taskId)
        numberOfWinnersFull(msg.sender, _learningPathId, _taskId)
        onceVerified(msg.sender, _learningPathId, _taskId)
    {
        user[_user].attemptedTasks[msg.sender][_learningPathId][_taskId] = UserTaskStatus.Verified;
        user[_user].xp += learningPath[msg.sender][_learningPathId].task[_taskId].xp;

        learningPath[msg.sender][_learningPathId].task[_taskId].winnerUsers.push(_user);

        _onceVerified[msg.sender][_learningPathId][_taskId] = true;

        // Leveling system = 100*2^(level-1)
        // Level 1 = 100 xp
        // Level 2 = 200 xp
        // Level 3 = 400 xp
        if(user[_user].xp > 100*2**(user[_user].level - 1)){
            user[_user].level++;
        }

        emit VerifyTaskAttempt(
            _user, 
            _learningPathId,
            _taskId, 
            learningPath[msg.sender][_learningPathId].task[_taskId].xp, 
            msg.sender, 
            block.timestamp
        );
    }

    function rejectTask(
        address _user, 
        uint256 _learningPathId,
        uint256 _taskId
    )
        external
        isEducator(msg.sender)
        isUser(_user)
        isUserSuspended(_user)
        learningPathAvailable(msg.sender, _learningPathId)
        userAttempted(_user, msg.sender, _learningPathId, _taskId)
        onceRejected(msg.sender, _learningPathId, _taskId)
    {
        user[_user].attemptedTasks[msg.sender][_learningPathId][_taskId] = UserTaskStatus.Rejected;

        _onceRejected[msg.sender][_learningPathId][_taskId] = true;

        emit RejectTaskAttempt(
            _user, 
            _learningPathId,
            _taskId, 
            msg.sender, 
            block.timestamp
        );
    }

    // Task Functions

    function createTask(
        uint256 _xp,
        string memory _name,
        string[] memory _tags,
        uint256 _deadline,
        uint256 _numberOfWinners
    ) 
        private 
        isEducator(msg.sender)
    {
        require(_xp != 0, "XP couldn't be 0");
        address[] memory emptyAddressList;

        if(_deadline == 0 && _numberOfWinners == 0){
            Task memory newTask = Task({
                xp: _xp,
                name: _name,
                tags: _tags,
                deadline: block.timestamp + 999999 days,
                numberOfWinners: 999999,
                attemptedUsers: emptyAddressList,
                winnerUsers: emptyAddressList
            });

            learningPath[msg.sender][learningPath[msg.sender].length - 1].task.push(newTask);
        }
        else if(_deadline == 0 && _numberOfWinners != 0){
            Task memory newTask = Task({
                xp: _xp,
                name: _name,
                tags: _tags,
                deadline: block.timestamp + 999999 days,
                numberOfWinners: _numberOfWinners,
                attemptedUsers: emptyAddressList,
                winnerUsers: emptyAddressList
            });

            learningPath[msg.sender][learningPath[msg.sender].length - 1].task.push(newTask);
        }
        else if(_deadline != 0 && _numberOfWinners == 0){
            Task memory newTask = Task({
                xp: _xp,
                name: _name,
                tags: _tags,
                deadline: block.timestamp + _deadline,
                numberOfWinners: 999999,
                attemptedUsers: emptyAddressList,
                winnerUsers: emptyAddressList
            });

            learningPath[msg.sender][learningPath[msg.sender].length - 1].task.push(newTask);
        }
        else {
            Task memory newTask = Task({
                xp: _xp,
                name: _name,
                tags: _tags,
                deadline: block.timestamp + _deadline,
                numberOfWinners: _numberOfWinners,
                attemptedUsers: emptyAddressList,
                winnerUsers: emptyAddressList
            });

            learningPath[msg.sender][learningPath[msg.sender].length - 1].task.push(newTask);
        }

        emit TaskCreated(
            msg.sender,
            learningPath[msg.sender].length - 1, 
            learningPath[msg.sender][learningPath[msg.sender].length - 1].task.length, 
            block.timestamp
        );
    }

    function getTaskInfo(
        address _educator, 
        uint256 _learningPathId,
        uint256 _taskId
    )
        external
        view
        returns(Task memory)
    {
        return learningPath[_educator][_learningPathId].task[_taskId];
    }

    // Learning Path Functions

    function createLearningPath(
        string memory _learningPathName,
        uint256[] memory _xp,
        string[] memory _taskName,
        string[][] memory _tags,
        uint256[] memory _deadline,
        uint256[] memory _numberOfWinners
    )
        external
        isEducator(msg.sender)
    {
        Task[] memory emptyTask;
        LearningPath memory newPath = LearningPath({
            name: _learningPathName,
            status: LearningPathStatus.Draft,
            task: emptyTask
        });

        learningPath[msg.sender].push(newPath);

        for(uint i = 0; i < _xp.length; i++){
            createTask(
                _xp[i],
                _taskName[i],
                _tags[i],
                _deadline[i],
                _numberOfWinners[i]
            );
        }
    }

    function inactivateLearningPath( uint256 _id ) 
        external 
        isEducator(msg.sender) 
        learningPathAvailable(msg.sender, _id)
    {
        learningPath[msg.sender][_id].status = LearningPathStatus.Inactive;

        emit LearningPathInactivated(msg.sender, _id, block.timestamp);
    }


    function activateLearningPath( uint256 _id ) 
        external 
        isEducator(msg.sender) 
        pathReadyToActivate(msg.sender, _id) 
    {
        learningPath[msg.sender][_id].status = LearningPathStatus.Inactive;

        emit LearningPathActivated(msg.sender, _id, block.timestamp);
    }

    // Admin Functions

    function deleteUser( address _user ) external onlyOwner {
        for ( uint i = 0; i < userList.length; i++ ){
            if( userList[i] == _user ){
                delete userList[i];
                delete user[_user];
                _isUser[_user] = false;
                deletedUser[_user] = true;
                break;
            }
        }

        emit UserDeleted(_user, block.timestamp);
    }

    function suspendUser( address _user ) 
        external 
        onlyOwner 
        isUser(_user)
        isUserSuspended(_user) 
    {
        user[_user].isSuspended = true;

        emit UserSuspended(_user, block.timestamp);
    }

    function unsuspendUser( address _user ) 
        external 
        onlyOwner 
        isUser(_user) 
    {
        user[_user].isSuspended = false;

        emit UserUnsuspended(_user, block.timestamp);
    }

    function addEducator( 
        address _educator, 
        string memory _name, 
        string memory _communityName 
    ) 
        external 
        onlyOwner 
    {
        require( 
            !( _isEducator[msg.sender] ), 
            "The educator already added!" 
        );
        require( 
            !( deletedEducator[msg.sender] ), 
            "The educator's account has been deleted!" 
        );
        require( 
            !( onlyOneEducator[_communityName] ), 
            "This community has a educator!" 
        );

        _isEducator[_educator] = true;

        Educator memory newEducator = Educator({
            name: _name,
            communityName: _communityName
        });

        educator[_educator] = newEducator;
        onlyOneEducator[_communityName] = true;

        emit EducatorAdded(_educator, block.timestamp);
    }

    function deleteEducator( address _educator ) external onlyOwner {
        delete educator[_educator];
        _isEducator[_educator] = false;

        emit EducatorDeleted(_educator, block.timestamp);
    }

    function adminInactivatePath(address _educator, uint256 _id) external onlyOwner
    {
        learningPath[_educator][_id].status = LearningPathStatus.Inactive;

        emit AdminInctivatedPath(_educator, _id, block.timestamp);
    }

    function adminActivatePath(address _educator, uint256 _id) external onlyOwner
    {
        learningPath[_educator][_id].status = LearningPathStatus.Active;

        emit AdminActivatedPath(_educator, _id, block.timestamp);
    }

    function adminVerifyTask(
        address _user,
        address _educator, 
        uint256 _learningPathId,
        uint256 _taskId
    ) 
        external 
        isEducator(_educator)
        isUser(_user)
        isUserSuspended(_user)
        learningPathAvailable(_educator, _learningPathId)
        userAttempted(_user, _educator, _learningPathId, _taskId)
        numberOfWinnersFull(_educator, _learningPathId, _taskId)
        onlyOwner
    {
        user[_user].attemptedTasks[_educator][_learningPathId][_taskId] = UserTaskStatus.Verified;
        user[_user].xp += learningPath[_educator][_learningPathId].task[_taskId].xp;

        learningPath[_educator][_learningPathId].task[_taskId].winnerUsers.push(_user);

        emit AdminVerifyTaskAttempt(
            _user, 
            _learningPathId,
            _taskId, 
            learningPath[msg.sender][_learningPathId].task[_taskId].xp, 
            _educator, 
            block.timestamp
        );
    }

    function adminRejectTask(
        address _user,
        address _educator, 
        uint256 _learningPathId,
        uint256 _taskId
    )
        external
        isEducator(_educator)
        isUser(_user)
        isUserSuspended(_user)
        learningPathAvailable(_educator, _learningPathId)
        userAttempted(_user, _educator, _learningPathId, _taskId)
        onlyOwner
    {
        user[_user].attemptedTasks[_educator][_learningPathId][_taskId] = UserTaskStatus.Rejected;

        emit AdminRejectTaskAttempt(
            _user, 
            _learningPathId,
            _taskId, 
            _educator, 
            block.timestamp
        );
    }

    function adminEditXp(address _user, uint256 _xp) external onlyOwner {
        user[_user].xp = _xp;

        emit AdminEditedXp(_user, _xp, block.timestamp);
    }

    function shutdown() external onlyOwner {
        selfdestruct(payable(owner));
    }
    
    function withdraw() external payable onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    fallback() external payable {}
}