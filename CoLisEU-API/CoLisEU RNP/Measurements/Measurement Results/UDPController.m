//
//  UDPViewController.m
//  CoLisEU RNP
//
//  Created by Cassiano Padilha on 08/06/15.
//  Copyright (c) 2015 GT-CoLisEU. All rights reserved.
//

#import "UDPViewController.h"
#define kOBSk @"UDPKey"

#pragma mark * Utilities

@interface UDPViewController ()
@end

@implementation UDPViewController
@synthesize hostView = hostView_;
@synthesize pinger    = _pinger;
@synthesize sendTimer = _sendTimer;
int Flag;

-(void)SuportLanguage{
    self.title = [Translate getNetworkTest];
    self.lbAverage.text = [Translate getAverage];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self SuportLanguage];
    MPoint *mp = [MPoint sharedMPoint];
    
    graphUDP = [[NSMutableArray alloc]init];
    plotUDP = [[NSMutableArray alloc]init];
    
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading";
    [IPerfController addObserver:kOBSk obj:self];
    
    NetworkInfo *network = [[NetworkInfo alloc]init];
    self.lbDate.text = [NSString stringWithFormat:@"Date: %@",[network getTimeStamp]];
    self.lbSSID.text = [NSString stringWithFormat:@"SSID: %@",[network getSSID]];
    self.lbIP.text = [NSString stringWithFormat:@"Server: %@",[mp address]];
    
    [[IPerfController getInstance] startUDP];
}
-(void)initPlotUDP{
    NameTest = @"UDP";
    
    NSLog(@"udp down %@",[IPerfController getInstance].UdpDown);
    NSLog(@"udp upd %@",[IPerfController getInstance].UdpUp);
    
    NSLog(@"udp down %f",[[[IPerfController getInstance].UdpDown valueForKeyPath:@"@sum.floatValue"] floatValue]);
    NSLog(@"udp up %f",[[[IPerfController getInstance].UdpUp valueForKeyPath:@"@sum.floatValue"] floatValue]);
    
    AverageUDPDown = @([[[IPerfController getInstance].UdpDown valueForKeyPath:@"@sum.floatValue"] floatValue]/5/128);
    AverageUDPUp = @([[[IPerfController getInstance].UdpUp valueForKeyPath:@"@sum.floatValue"] floatValue]/5/128);
    
    self.lbDownload.text = [NSString stringWithFormat:@"%.2f Mbit/s",[AverageUDPDown floatValue]];
    self.lbUpload.text = [NSString stringWithFormat:@"%.2f Mbit/s",[AverageUDPUp floatValue]];
    
    Flag = 0;
    
    [[NetworkTestList sharedNetworkList].UDPdownList addObject:[IPerfController getInstance].UdpDown];
    [[NetworkTestList sharedNetworkList].UDPupList addObject:[IPerfController getInstance].UdpUp];    
    [[NetworkTestList sharedNetworkList].LostPacketPercent addObject:[IPerfController getInstance].LostPacketPercent];
    
    [self ConfigureTest:@"UDP" testSelected:3 testView:self.UDPView];
}
-(void) ConfigureTest:(NSString *)nametest testSelected:(NSInteger *)testselect testView:(UIView *)view{
    [self configureHost:view];
    TestSelected = testselect;
    NameTestSelected = nametest;
    NSLog(@"configure graph");
    [self configureGraph];
    NSLog(@"configure plots");
    [self configurePlots];
    NSLog(@"configure axes");
    [self configureAxes];
    if([nametest isEqualToString:@"RTT"])
        Ploted = true;
    NSLog(@"PLOTOUUUU");
    hud.hidden = YES;
   // [[IPerfController getInstance] stop];
    NSThread *t = [[NSThread alloc] initWithTarget:self selector:@selector(nextTest) object:nil];
    [t start];
}
-(void)configureHost:(UIView *)vGraph {
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:vGraph.bounds];
    self.hostView.allowPinchScaling = YES;
    
    vGraph.layer.cornerRadius = 3.0;
    
    //    vGraph.layer.cornerRadius = self.viewAverage.layer.cornerRadius = 3.0;
    //    self.viewAverage.layer.borderColor = [UIColor blackColor].CGColor;
    //
    //    self.viewAverage.layer.borderWidth =  0.5f;
    [vGraph addSubview:self.hostView];
}

-(void)configureGraph { // Responsável pelo eixo e título do gráfico e pela anição do scroll
    NSLog(@"configure graph");
    // 1 - Create the graph
    ///CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    
    //[graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    graph.paddingLeft = 0.0;
    graph.paddingBottom = 0.0;
    self.hostView.hostedGraph = graph;
    
    // 2 - Set graph title
    graph.title = NameTest; // Primeiro gráfico a ser exibido é RTT
    
    // 3 - Create and set text style
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    
    titleStyle.color = [CPTColor blackColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 13.0f;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, 10.0f);
    // 4 - Set padding for plot area
    [graph.plotAreaFrame setPaddingLeft:40.0f]; // Espaço na lateral esquerda
    [graph.plotAreaFrame setPaddingBottom:30.0f];
    // 5 - Enable user interactions for plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
}

-(void)configurePlots {  // Responsável por plotar o gráfico, ou seja monta o gráfico
    NSLog(@"configure plots");
    
    // 1 - Get graph and plot space
    //CPTGraph *graph = self.hostView.hostedGraph;
    graph = self.hostView.hostedGraph;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    // 2 - Create the three plots
    
    //CPTScatterPlot *aaplPlot = [[CPTScatterPlot alloc] init];  ///Primeira Linha do Gráfico (Vermelha)
    aaplPlot = [[CPTScatterPlot alloc] init];  ///Primeira Linha do Gráfico (Vermelha)
    
    aaplPlot.dataSource = self;
    aaplPlot.identifier = CPDTickerSymbolAAPL;
    CPTColor *aaplColor = [CPTColor redColor];
    [graph addPlot:aaplPlot toPlotSpace:plotSpace];
    
    
    //  CPTScatterPlot *googPlot = [[CPTScatterPlot alloc] init]; ///Segunda Linha do Gráfico (Verde)
    googPlot = [[CPTScatterPlot alloc] init]; ///Segunda Linha do Gráfico (Verde)
    googPlot.dataSource = self;
    googPlot.identifier = CPDTickerSymbolGOOG;
    CPTColor *googColor;
    
    
    if (TestSelected != 0){ // Significa que o teste não é RTT, então terá mais de uma reta
        NSLog(@"rtt!");
        googColor = [CPTColor blueColor];
        [graph addPlot:googPlot toPlotSpace:plotSpace];
    }
    
    if([NameTest isEqualToString:@"UDP"]){
        [graphUDP addObject:graph];
        [plotUDP addObject:aaplPlot];
        [plotUDP addObject:googPlot];
    }
    NSLog(@"configure plots 1");
    
    
    //CPTScatterPlot *msftPlot = [[CPTScatterPlot alloc] init]; //Terceira  linha do Gráfico (azul)
    msftPlot = [[CPTScatterPlot alloc] init]; //Terceira  linha do Gráfico (azul)
    msftPlot.dataSource = self;
    msftPlot.identifier = CPDTickerSymbolMSFT;
    
    //CPTColor *msftColor = [CPTColor blueColor];
    //[graph addPlot:msftPlot toPlotSpace:plotSpace];
    
    NSLog(@"configure plots 2");
    
    
    // 3 - Set up plot space
    if(TestSelected != 0)
        [plotSpace scaleToFitPlots:@[aaplPlot, googPlot,msftPlot]];
    else
        [plotSpace scaleToFitPlots:@[aaplPlot,msftPlot]];
    
    CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
    [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.1f)];
    plotSpace.xRange = xRange;
    
    NSLog(@"configure plots 3");
    
    CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
    [yRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    plotSpace.yRange = yRange;
    // 4 - Create styles and symbols
    
    NSLog(@"configure plots 4");
    
    CPTMutableLineStyle *aaplLineStyle = [aaplPlot.dataLineStyle mutableCopy];
    aaplLineStyle.lineWidth = 1.080;
    aaplLineStyle.lineColor = aaplColor;
    aaplPlot.dataLineStyle = aaplLineStyle;
    CPTMutableLineStyle *aaplSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    aaplSymbolLineStyle.lineColor = aaplColor;
    CPTPlotSymbol *aaplSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    aaplSymbol.fill = [CPTFill fillWithColor:aaplColor];
    aaplSymbol.lineStyle = aaplSymbolLineStyle;
    aaplSymbol.size = CGSizeMake(6.0f, 6.0f);
    aaplPlot.plotSymbol = aaplSymbol;
    
    NSLog(@"configure plots 5");
    
    CPTMutableLineStyle *googLineStyle = [googPlot.dataLineStyle mutableCopy];
    googLineStyle.lineWidth = 1.080;
    googLineStyle.lineColor = googColor;
    googPlot.dataLineStyle = googLineStyle;
    CPTMutableLineStyle *googSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    googSymbolLineStyle.lineColor = googColor;
    CPTPlotSymbol *googSymbol = [CPTPlotSymbol starPlotSymbol];
    googSymbol.fill = [CPTFill fillWithColor:googColor];
    googSymbol.lineStyle = googSymbolLineStyle;
    googSymbol.size = CGSizeMake(6.0f, 6.0f);
    googPlot.plotSymbol = googSymbol;
    
    
    NSLog(@"end init plot");
}
-(void)ConfigureLegends{
    NSLog(@"configure legends");
    if ((int)TestSelected == 3){
        minorIncrement = majorIncrement = 1;
        if((int)majorIncrement < 1){
            NSLog(@"Menor que 1");
            minorIncrement = majorIncrement = 1;
        }
        else
            NSLog(@"maior que 1");
        NSLog(@"mino and major %d",(int)minorIncrement);
        
    }
    
}
-(void)configureAxes {
    [self ConfigureLegends];
    
    // 1 - Create styles
    CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
    axisTitleStyle.color = [CPTColor blackColor];
    axisTitleStyle.fontName = @"Helvetica-Bold";
    axisTitleStyle.fontSize = 6.0f;
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 0.08f;  // Linha dos eixos X e Y (Horizontal e vertical)
    axisLineStyle.lineColor = [CPTColor blackColor];
    
    
    CPTMutableTextStyle *axisTextStyle = [[CPTMutableTextStyle alloc] init]; // Responsável pelos intervalos do gráfico, tanto eixo x como eixo y
    axisTextStyle.color = [CPTColor blackColor];
    axisTextStyle.fontName = @"Helvetica-Bold";
    axisTextStyle.fontSize = 6.0f;
    
    
    
    CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle]; // Linhas horizontais que traçam o gráfico
    gridLineStyle.lineColor = [CPTColor blackColor];
    gridLineStyle.lineWidth = 0.08f;
    
    CPTMutableLineStyle *gridLineStyle_X = [CPTMutableLineStyle lineStyle]; // Linhas verticais que traçam o gráfico
    gridLineStyle_X.lineColor = [CPTColor blackColor];
    gridLineStyle_X.lineWidth = 0.08f;
    
    // 2 - Get axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    // 3 - Configure x-axis
    CPTAxis *x = axisSet.xAxis;
    x.titleTextStyle = axisTitleStyle;
    x.titleOffset = 13.0f;
    x.axisLineStyle = axisLineStyle;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.labelTextStyle = axisTextStyle;
    x.majorTickLineStyle = axisLineStyle;
    x.majorTickLength = 4.0f;
    x.tickDirection = CPTSignNegative;
    CGFloat dateCount = [[[CPDStockPriceStore sharedInstance] datesInMonth] count];
    NSMutableSet *xLabels = [NSMutableSet setWithCapacity:dateCount];
    NSMutableSet *xLocations = [NSMutableSet setWithCapacity:dateCount];
    NSInteger i = 0;
    for (NSString *date in [[CPDStockPriceStore sharedInstance] datesInMonth]) {
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:date  textStyle:x.labelTextStyle];
        CGFloat location = i++;
        label.tickLocation = CPTDecimalFromCGFloat(location);
        label.offset = x.majorTickLength;
        if (label) {
            [xLabels addObject:label];
            [xLocations addObject:[NSNumber numberWithFloat:location]];
        }
    }
    x.axisLabels = xLabels;
    x.majorTickLocations = xLocations;
    // 4 - Configure y-axis
    CPTAxis *y = axisSet.yAxis;
    x.title = @"";
    //y.title = @"(ms)";
    if (NameTestSelected == nil) {
        NameTestSelected = @"RTT";
    }
    NSString *formatTest = (int)TestSelected == 0 || (int)TestSelected == 1 ? @"(ms)" : @"(Mbit/s)";
    y.title = [NSString stringWithFormat:@"%@ %@",NameTestSelected,formatTest];
    // y.title = [NSString stringWithFormat:@"%@ (ms)",NameTestSelected];
    y.titleTextStyle = axisTitleStyle;
    y.titleOffset = -30.0f;
    y.axisLineStyle = axisLineStyle;
    y.majorGridLineStyle = gridLineStyle;
    x.majorGridLineStyle = gridLineStyle_X;
    
    y.labelingPolicy = CPTAxisLabelingPolicyNone;
    y.labelTextStyle = axisTextStyle;
    y.labelOffset = 15.0f;
    y.majorTickLineStyle = axisLineStyle;
    
    axisSet.yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    axisSet.xAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    
    y.majorTickLength = 4.0f;
    y.minorTickLength = 2.0f;
    y.tickDirection = CPTSignPositive;
    
    
    
    CGFloat yMax = 900.0f;  // should determine dynamically based on max price
    NSMutableSet *yLabels = [NSMutableSet set];
    NSMutableSet *yMajorLocations = [NSMutableSet set];
    NSMutableSet *yMinorLocations = [NSMutableSet set];
    
    for (NSInteger j = minorIncrement; j <= yMax; j += minorIncrement) {
        NSUInteger mod = j % majorIncrement;
        if (mod == 0) {
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%li", (long)j] textStyle:y.labelTextStyle];
            NSDecimal location = CPTDecimalFromInteger(j);
            label.tickLocation = location;
            label.offset = -y.majorTickLength - y.labelOffset;
            if (label) {
                [yLabels addObject:label];
            }
            [yMajorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:location]];
        } else {
            [yMinorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:CPTDecimalFromInteger(j)]];
        }
    }
    y.axisLabels = yLabels;
    y.majorTickLocations = yMajorLocations;
    y.minorTickLocations = yMinorLocations;
}

#pragma mark - Rotation
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return [[[CPDStockPriceStore sharedInstance] datesInMonth] count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    //NSLog(@"number plot");
    ///NSLog(@"index %lu %@",(unsigned long)index,plot.identifier);
    NSInteger valueCount = [[[CPDStockPriceStore sharedInstance] datesInMonth] count];
    
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            if (index < valueCount) {
                //NSLog(@"index %i %@",index,[NSNumber numberWithUnsignedInteger:index]);
                return @(index);
            }
            break;
        case CPTScatterPlotFieldY:
            switch ((int)TestSelected) {
                case 3:
                    if ([plot.identifier isEqual:CPDTickerSymbolAAPL] == YES){
                        NSLog(@"value %@ index %i",[IPerfController getInstance].UdpDown[index],index);
                        return [NSNumber numberWithFloat:[[IPerfController getInstance].UdpDown[index] floatValue]/128];
                    }
                    else if ([plot.identifier isEqual:CPDTickerSymbolGOOG] == YES)
                        return [NSNumber numberWithFloat:[[IPerfController getInstance].UdpUp[index] floatValue]/128];
                    break;
                default:
                    break;
            }
            break;
    }
    return [NSDecimalNumber zero];
}
-(void)update:(TestType)notification{
    NSLog(@"notification %u",notification);
    switch (notification) {
        case UDP:
            if(![IPerfController getInstance].error){
                NSThread *t = [[NSThread alloc] initWithTarget:self selector:@selector(initPlotUDP) object:nil];
                [t start];
            }
            break;
        default:
            break;
    }
}
- (BOOL)slideNavigationControllerShouldDisplayLeftMenu{
    return YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
-(void)nextTest{
    sleep(1);
    [ScreenLoadController showTestJitter:self.slideOutAnimationEnabled];
}
- (IBAction)btnNextTest:(id)sender {
    [ScreenLoadController showTestJitter:self.slideOutAnimationEnabled];

}
@end
