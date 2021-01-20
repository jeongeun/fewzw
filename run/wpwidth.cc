#include <iostream>

using namespace std;

int main(int argc, char** argv){
        double mWp = atof(argv[1]);

        double mW = 80.403;
        double widthW = 2.141;

        double widthWp = 4.0 / 3.0 * mWp / mW * widthW;
        double widthWplv = widthWp / 12.0 ;

        cout << "M(W')= " << mWp << " width(W')= " << widthWp << " width(W'->lv)= " << widthWplv << " width(W'->lv)/width(W')= " << widthWplv / widthWp << endl;

return 0;
}
