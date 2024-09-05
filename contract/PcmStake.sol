// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract PCMStakeBase is Ownable {
    event FundsDeposited(address user, uint256 amount);
    event FundsWithdrawn(address user, uint256 amount);
    event FundsDistributed(address indexed user, uint256 amount);

    event UserDeposited(address indexed user, uint256 amount);
    event UserWithdrawn(address indexed user, uint256 amount);

    IERC20 public token;

    uint256 private _funds;
    uint256 private _totalStaked;
    mapping(address => uint256) public balanceOf;

    /**
     * @dev Add bonus funds to the contract
     */
    function addBonusFunds(uint256 _amount) public {
        _funds += _amount;
        token.transferFrom(_msgSender(), address(this), _amount);
        emit FundsDeposited(_msgSender(), _amount);
    }

    /**
     * @dev Withdraw bonus funds from the contract, only owner can call this function
     */
    function withdrawBonusFunds(uint256 _amount) public onlyOwner {
        require(_funds >= _amount, "PCM::InsufficientFunds");
        _funds -= _amount;
        token.transfer(_msgSender(), _amount);
        emit FundsWithdrawn(_msgSender(), _amount);
    }

    function distributeBonus(address _user, uint256 _amount) internal  {
        require(_funds >= _amount, "PCM::InsufficientFunds");
        _funds -= _amount;
        token.transfer(_user, _amount);
        emit FundsDistributed(_user, _amount);
    }

    function userDeposit(address _user, uint256 _amount) internal {
        token.transferFrom(_user, address(this), _amount);
        balanceOf[_user] += _amount;
        _totalStaked += _amount;
        emit UserDeposited(_user, _amount);
    }

    function userWithdraw(address _user, uint256 _amount) internal {
        balanceOf[_user] -= _amount;
        _totalStaked -= _amount;
        token.transfer(_user, _amount);
        emit UserWithdrawn(_user, _amount);
    }

    function getTotalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function getFunds() public view returns (uint256) {
        return _funds;
    }
}

contract PCMStake is PCMStakeBase {
    enum StakeType { s90Days, s180Days, s1Year, s2Year, s3Year }

    struct StakeDetails {
        bool isWithdrawn;
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 reward;
        uint256 apr;
    }

    struct StakeReward {
        uint256 duration;
        uint16[10] apr;
        uint32[120] limit;
    }

    event StakeEvent(uint256 stakeId, address indexed user, StakeType indexed stakeType, uint256 amount, uint256 apr, uint256 start, uint256 end);

    uint256 constant public BASE = 10000;
    uint256 constant public MAX_STAKE_COUNT = 20;
    uint256 constant public MIN_STAKE_AMOUNT = 10 ether;

    uint256 immutable public luanchTime;
    uint256 public stakeId = 0;

    mapping(StakeType => StakeReward) private stakeData;
    mapping(address => uint256[]) private userStakes;
    mapping(uint256 => StakeDetails) public stakes;
    mapping(uint256 => mapping(StakeType => uint256)) public staked;

    constructor(address _token) Ownable(_msgSender()) {
        token = IERC20(_token);
        luanchTime = block.timestamp;
        initdata();
    }

    function initdata() internal {
        stakeData[StakeType.s90Days] = StakeReward({
            duration: 90 days,
            apr: [1200, 800, 533, 356, 237, 237, 237, 237, 237, 237],
            limit: [
                830333, 214558, 212875, 236824, 235532, 260869, 326374, 330097, 335199, 339248, 342809, 391001, 
	            1046304, 728522, 752297, 763596, 774855, 808678, 826045, 844187, 861327, 877456, 893909, 1013383, 
	            1400256, 1016459, 1052565, 1078740, 1106173, 1147644, 1173319, 1200646, 1227525, 1253899, 1169052, 1443130, 
	            1717072, 1201443, 1251958, 1293414, 1337657, 1395735, 1436235, 1480282, 1525193, 1571137, 1626184, 1727585, 
	            1777542, 1005285, 1059041, 1107946, 1163563, 1220180, 1269736, 1327117, 1388465, 1455181, 1533474, 1579122, 
	            1365612, 1417461, 1470079, 1525412, 1584591, 1643052, 1705392, 1771340, 1841251, 1917145, 1992545, 1982761, 
	            1918416, 1961127, 2005097, 2050200, 2096397, 2143474, 2191952, 2242150, 2294347, 2349663, 2399743, 2390972, 
	            2200350, 2254242, 2306637, 2362203, 2418534, 2472175, 2530807, 2591939, 2656099, 2722808, 2772534, 2843742, 
	            2711525, 2829443, 2949909, 3080802, 3220818,3362980, 3521412, 3692945, 3879602, 4079163, 4266656, 4554744, 
	            4973150, 5465742, 6053231, 6763281,7636965, 9116160, 11236218, 14530800, 22257338, 0, 0, 0
            ]	
        });

        stakeData[StakeType.s180Days] = StakeReward({
            duration: 180 days,
            apr: [1500, 1000, 667, 444, 296, 296, 296, 296, 296, 296],
            limit: [
                830333, 214558, 212875, 233451, 232938, 237464, 321064, 325911, 330059, 334933, 339153, 370464, 
                1038879, 724612, 732613, 754035, 766709, 783593, 809903, 829473, 847860, 865087, 882494, 967551, 
                1360764, 989550, 1019907, 1053778, 1082031, 1115190, 1148664, 1176650, 1204152, 1231115, 1262587, 1259397, 
                1657828, 1160452, 1206664, 1254560, 1297989, 1350132, 1398335, 1441718, 1485943, 1531172, 1585276, 1657424, 
                1697766, 958821, 1008255, 1061023, 1112918, 1165143, 1220862, 1274806, 1332347, 1394795, 1468046, 1488110, 
                1323862, 1373440, 1425495, 1478400, 1534928, 1592839, 1652375, 1715280, 1781881, 1854114, 1925691, 1913063, 
                1887842, 1929875, 1973140, 2017512, 2062952, 2109249, 2156916, 2206265, 2257570, 2311934, 2361134, 2328238, 
                2158239, 2210718, 2264380, 2318603, 2373544, 2428803, 2486129, 2545880, 2608576, 2673741, 2722198, 2744689, 
                2614670, 2725693, 2843115, 2966240, 3097659, 3236076, 3384680, 3545213, 3719495, 3905249, 4078442, 4225992, 
                4590257, 5014481, 5513961, 6108419, 6826335, 7721803,       0,       0,       0,       0,       0, uint32(0)
            ]
        });

        stakeData[StakeType.s1Year] = StakeReward({
            duration: 365 days,
            apr: [2000, 1333, 888, 592, 395, 395, 395, 395, 395, 395],
            limit: [
                1245500,  321837,  319313,  350177,  349407,  356197,  481596,  488867,  495088,  502400,  508730,  555696, 
                1558319, 1086918, 1098919, 1131053, 1150064, 1175390, 1214855, 1244210, 1271791, 1297631, 1323742, 1451327, 
                2041146, 1484325, 1529860, 1580667, 1623046, 1672786, 1722997, 1764976, 1806228, 1846673, 1893880, 1889096, 
                2486743, 1740678, 1809997, 1881841, 1946984, 2025198, 2097503, 2162577, 2228914, 2296759, 2377914, 2486136, 
                2546649, 1438232, 1512383, 1591535, 1669378, 1747714, 1831294, 1912209, 1998521, 2092193, 2202069, 2232166, 
                1985794, 2060160, 2138242, 2217601, 2302392, 2389258, 2478562, 2572921, 2672822, 2781171, 2888537, 2869595, 
                2831763, 2894813, 2959710, 3026268, 3094428, 3163874, 3235375, 3309398, 3386356, 3467901, 3541701, 3492358, 
                3237358, 3316077, 3396570, 3477904, 3560317, 3643205, 3729193, 3818820, 3912864, 4010612, 4083298, 4117033, 
                3922005, 4088540, 4264672, 4449361, 4646489, 4854115, 5077020, 5317820, 5579243, 5857874, 6117663, 6338988,
                      0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0, uint32(0)
            ]
        });

        stakeData[StakeType.s2Year] = StakeReward({
            duration: 730 days,
            apr: [2500, 1667, 1111, 741, 494, 494, 494, 494, 494, 494],
            limit: [
                 830333,  214558,  212875,  233451,  232938,  237464,  321064,  325911,  330059,  334933,  339153,  370464, 
                1038879,  724612,  732613,  754035,  766709,  783593,  809903,  829473,  847860,  865087,  882494,  967551, 
                1360764,  989550, 1019907, 1053778, 1082031, 1115190, 1148664, 1176650, 1204152, 1231115, 1262587, 1259397, 
                1657828, 1160452, 1206664, 1254560, 1297989, 1350132, 1398335, 1441718, 1485943, 1531172, 1585276, 1657424, 
                1697766,  958821, 1008255, 1061023, 1112918, 1165143, 1220862, 1274806, 1332347, 1394795, 1468046, 1488110, 
                1323862, 1373440, 1425495, 1478400, 1534928, 1592839, 1652375, 1715280, 1781881, 1854114, 1925691, 1913063, 
                1887842, 1929875, 1973140, 2017512, 2062952, 2109249, 2156916, 2206265, 2257570, 2311934, 2361134, 2328238, 
                2158239, 2210718, 2264380, 2318603, 2373544, 2428803, 2486129, 2545880, 2608576, 2673741, 2722198, 2744689,
                      0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,
                      0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0, uint32(0)
            ]
        });

        stakeData[StakeType.s3Year] = StakeReward({
            duration: 1095 days,
            apr: [3000, 2000, 1333, 889, 593, 593, 593, 593, 593, 593],
            limit: [
                415166, 107279, 106437,  116725,  116469,  118732,  160532,  162955,  165029,  167466,  169576,  185232, 
                519439, 362306, 366306,  377017,  383354,  391796,  404951,  414736,  423930,  432543,  441247,  483775, 
                680382, 494775, 509953,  526889,  541015,  557595,  574332,  588325,  602076,  615557,  631293,  629698, 
                828914, 580226, 603332,  627280,  648994,  675066,  699167,  720859,  742971,  765586,  792638,  828712, 
                848883, 479410, 504127,  530511,  556459,  582571,  610431,  637403,  666173,  697397,  734023,  744055, 
                661931, 686720, 712747,  739200,  767464,  796419,  826187,  857640,  890940,  927057,  962845,  956531, 
                943921, 964937, 986570, 1008756, 1031476, 1054624, 1078458, 1103132, 1128785, 1155967, 1180567, 1164119,  
                     0,      0,      0,       0,       0,       0,       0,       0,       0,       0,       0,       0,
                     0,      0,      0,       0,       0,       0,       0,       0,       0,       0,       0,       0,
                     0,      0,      0,       0,       0,       0,       0,       0,       0,       0,       0, uint32(0)
            ]
        });																															
    }

    function getStakeData(StakeType _type) public view returns (StakeReward memory) {
        return stakeData[_type];
    }

    /**
     * simulateReward
     */
    function simulateReward(StakeType _type, uint256 _amount) public view returns (uint256) {
        (uint256 _year, ) = getYearsMonth();
        StakeReward memory _stakeData = stakeData[_type];
        uint256 _apr = _stakeData.apr[_year-1];
        return _calculatedReward(_type, _amount, _apr);
    }

    /**
     * validateStake
     */
    function validateStake(StakeType _type, uint256 _amount) public view returns (bool pass,string memory message) {
        address sender = _msgSender();
        if (_amount < MIN_STAKE_AMOUNT) {
            return (false,"PCMStake::BelowMinimumStake");
        }
        if (userStakes[sender].length > MAX_STAKE_COUNT) {
            return (false,"PCMStake::MaxStakeCountExceeded");
        }
        (uint256 _year, uint256 _month) = getYearsMonth();
        if (_validateStakeAmount(_year, _month,_type,_amount)) {
            return (true,"PCMStake:: ValidateStake ok");
        } 
        return (false,"PCMStake::MaxStakeAmountExceeded");
    }

    /**
     * @dev Stake tokens to earn rewards
     */
    function stake(StakeType _type, uint256 _amount) public {
        address sender = _msgSender();
        require(_amount >= MIN_STAKE_AMOUNT, "PCMStake::BelowMinimumStake");
        require(userStakes[sender].length < MAX_STAKE_COUNT, "PCMStake::MaxStakeCountExceeded");

        (uint256 _year, uint256 _month) = getYearsMonth();
        userDeposit(sender, _amount);
        stakeId++;
        StakeReward memory _stakeData = stakeData[_type];
        uint256 _apr = _stakeData.apr[_year-1];
        stakes[stakeId] = StakeDetails({
            amount: _amount,
            start: block.timestamp,
            end: block.timestamp + _stakeData.duration,
            reward: _calculatedReward(_type, _amount, _apr),
            apr: _apr,
            isWithdrawn: false
        });

        userStakes[sender].push(stakeId);
        _updateStakeAmount(_year, _month, _type, _amount);
        emit StakeEvent(stakeId, sender, _type, _amount, _apr, block.timestamp, block.timestamp + _stakeData.duration);
    }

    /**
     * @dev Withdraw the staked tokens
     */
    function redeem() public {
        address sender = _msgSender();
        uint256[] memory _userStakes = userStakes[sender];
        bool _isWithdrawn = false;
        for (uint256 i = 0; i < _userStakes.length; i++) {
            StakeDetails storage _stake = stakes[_userStakes[i]];
            if (_stake.end <= block.timestamp && !_stake.isWithdrawn) {
                userWithdraw(sender, _stake.amount);
                distributeBonus(sender, _stake.reward);
                _stake.isWithdrawn = true;
                _isWithdrawn = true;
            }
        }
        require(_isWithdrawn, "PCM::NoStakeToUnlock");
    }

    /**
     * @dev Get the total amount of tokens that can be withdrawn by the user
     */
    function getUserWithdrawable(address _user) public view returns (uint256, uint256) {
        uint256 _deposit = 0;
        uint256 _reward = 0;
        uint256[] memory _userStakes = userStakes[_user];
        for (uint256 i = 0; i < _userStakes.length; i++) {
            StakeDetails memory _stake = stakes[_userStakes[i]];
            if (_stake.end <= block.timestamp && !_stake.isWithdrawn) {
                _deposit += _stake.amount;
                _reward += _stake.reward;
            }
        }
        return (_deposit, _reward);
    }

    /**
     * @dev Get years and month since the contract was launched
     */
    function getYearsMonth() public view returns (uint256, uint256) {
        uint256 _years = (block.timestamp - luanchTime) / 365 days + 1;
        uint256 _month = (block.timestamp - luanchTime) % 365 days / 30 days + 1;
        if (_month == 13) {
            _month = 12; // process the 361-365 days
        }
        return (_years, _month);
    }

    /**
     * @dev Get the list of stakes for a user
     */
    function getUserStakeList(address _user) public view returns (uint256[] memory, StakeDetails[] memory) {
        uint256[] memory _userStakes = userStakes[_user];
        StakeDetails[] memory stockList = new StakeDetails[](_userStakes.length);
        for (uint256 i = 0; i < _userStakes.length; i++) {
            StakeDetails memory _stake = stakes[_userStakes[i]];
            stockList[i] = _stake;
        }
        return (_userStakes,stockList);
    }

    function _updateStakeAmount(uint256 _year, uint256 _month, StakeType _type, uint256 _amount) internal {
        uint256 _index = (_year-1) * 12 + (_month - 1);
        staked[_index][_type] += _amount;
        require(staked[_index][_type] <= (uint256(stakeData[_type].limit[_index]) * 1 ether), "PCMStake::MaxStakeAmountExceeded");
    }

    function _validateStakeAmount(uint256 _year, uint256 _month, StakeType _type, uint256 _amount) internal view returns (bool) {
         uint256 _index = (_year-1) * 12 + (_month - 1);
         uint256 stock = staked[_index][_type];
         uint256 _stakeAmount = stock + _amount;
         if (_stakeAmount <= uint256(stakeData[_type].limit[_index]) * 1 ether) {
            return true;
         }
         return false;
    }

    function _calculatedReward(StakeType _type, uint256 _amount, uint256 _apr) internal pure returns (uint256) {
        if (_type == StakeType.s90Days) {
            return _amount * _apr / BASE * 90 / 365;
        } else if (_type == StakeType.s180Days) {
            return _amount * _apr / BASE * 180 / 365;
        } else if (_type == StakeType.s1Year) {
            return _amount * _apr / BASE * 365 / 365;
        } else if (_type == StakeType.s2Year) {
            return _amount * _apr / BASE * 730 / 365;
        } else if (_type == StakeType.s3Year) {
            return _amount * _apr / BASE * 1095 / 365;
        }
        return 0;
    }
}
